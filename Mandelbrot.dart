// Copyright 2012 David Karlsson
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import('dart:html');
#source('MandelIsolate.dart');
#source('VPoint.dart');
#source('FractParam.dart');
#source('ProgressAnimation.dart');
#source('Utils.dart');
#resource('Mandelbrot.css');

typedef void Callback();

class Mandelbrot {

  CanvasRenderingContext2D ctx;
  static final String ORANGE = "orange";
  FractParam fractParam;
  int runningJobs;
  var resizeHandle;
  Stopwatch jobTimer;
  
  Mandelbrot() {
    runningJobs  = 0;
    resizeHandle = -1;
    jobTimer     = new Stopwatch();
    
    CanvasElement canvas = document.query("#canvas");    
    
    ctx = canvas.getContext("2d");
    window.on.resize.add((event) => handleresize(canvas)); 
    
    canvas.on.click.add((event) => handleClick(event));
    canvas.width = window.innerWidth - 20;
    canvas.height = window.innerHeight - 20;
    
    fractParam = new FractParam(-5.1,4.0,-2.3 ,2.0 ,0,canvas.width,0,canvas.height);
    ProgressAnimation.startAnimation();
    drawFrame();
  }
  
  void handleClick(MouseEvent e) {
    FractParam f = fractParam;
    double xmid = f.x1 + (e.x / (f.dx2-f.dx1)) * (f.x2-f.x1);
    double xwinsize = f.x2 - f.x1;
    f.x1 = xmid - xwinsize/4;
    f.x2 = xmid + xwinsize/4;
    
    double ymid = f.y1 + (e.y / (f.dy2-f.dy1)) * (f.y2-f.y1);
    double ywinsize = f.y2 - f.y1;
    f.y1 = ymid - ywinsize/4;
    f.y2 = ymid + ywinsize/4;
    
    ProgressAnimation.startAnimation();
    drawFrame();
  }
  
  void handleresize(CanvasElement canvas) {
    canvas.width  = fractParam.dx2 = window.innerWidth  - 20;
    canvas.height = fractParam.dy2 = window.innerHeight - 20;
    
    if (resizeHandle != -1) {
      window.clearTimeout(resizeHandle);
    }
    ProgressAnimation.startAnimation();
    resizeHandle = window.setTimeout(() => drawFrame(), 1000);
    
  }

  List colormap(num maxval, num val) {
    
    return Utils.hsv(360 * val.toDouble()/(1000.0*10000.0),1,20);
    /**
    if (val > maxval) val = maxval;
    int mapval = ((val/maxval) * 0xFFFFFF).toInt();
    
    return [mapval & 0xFF0000, mapval & 0x00FF00, mapval & 0x0000FF];*/
  }
  
  /**
    * Creates an ImageData array from an array of (x,y,val) where val is the 
    * last value calculated in the fractal, and the val is used for choosing 
    * the color.
    */
  ImageData createImageData(CanvasRenderingContext2D ctx, List data, var width, var height) {
    ImageData img = ctx.createImageData(width, height);
    
    for (int i = 0; i < data.length; i+=3) {
      int x = data[i];
      int y = data[i+1];
      int v = data[i+2];
      
      var index = (y * width + x) * 4;
    
      var cmap = colormap(10000*10000,v);
      
      img.data[index]   = cmap[0];
      img.data[index+1] = cmap[1];
      img.data[index+2] = cmap[2];
      img.data[index+3] = 255;
    }
    return img;
  }

  void run() {}

  void write(String message) {
    // the HTML library defines a global "document" variable
    document.query('#status').innerHTML = message;
  }

void spawnNew(var xstep, var xdstep, ReceivePort receivePort, int n, double x1, double x2, double y1, double y2, int dx1,
final int dx2, int dy1, int dy2) {
    //print ("  spawnNew (x1,x2,xstep, n): $x1, $x2, $xstep, $n"); 
    Future f = new MandelIsolate().spawn();
    
    f.then((SendPort sendPort) {
      if (runningJobs++ == 0) {
        jobTimer.start();
        
      }
      var next = x1 + xstep;
      // No general serialization support in dart: send list 
      sendPort.send([x1, x1+xstep, y1,y2, dx1,dx1 +xdstep, dy1, dy2, n], receivePort.toSendPort());
  });
    
  if (n-- > 0) {
    spawnNew(xstep, xdstep,receivePort,n,x1+xstep,x2,y1,y2,dx1+xdstep,dx2,dy1,dy2);
  }
}

void calcsplit(ReceivePort receivePort, int n, double x1, double x2, double y1, double y2, int dx1, final int dx2, int dy1, int dy2) {
  print("Calcsplit: x:$x1 $x2 y:$y1 $y2 dx:$dx1 $dx2 dy:$dy1 $dy2");
  double xstep = (x2-x1)/n;
  int xdstep = ((dx2-dx1)/n).toInt();
  
  spawnNew(xstep,xdstep,receivePort,n-1,x1,x2,y1,y2,dx1,dx2,dy1,dy2);
}

void calcFrame(ReceivePort receivePort, FractParam f) {
  final int MAX_X = window.innerWidth-20;
  final int MAX_Y = window.innerHeight-20;
  
  calcsplit(receivePort, 2, f.x1, f.x2, f.y1, f.y2, f.dx1, f.dx2, f.dy1, f.dy2);
}

void setFractParams(double x1, double x2, double y1, double y2) {
  fractParam.x1 = x1;
  fractParam.x2 = x2;
  fractParam.y1 = y1;
  fractParam.y2 = y2;
  drawFrame();
}

void drawFrame() {
    
    final receivePort = new ReceivePort();
    receivePort.receive((List message, SendPort notUsedHere) {
      try {
        if (--runningJobs == 0) {
          jobTimer.stop();
          print("No more jobs, execution time: " + jobTimer.elapsedInMs() + "ms");
        }
        List drawWindow = message.getRange(0,4);
        var threadid = message[5];
        message.removeRange(0,5);
        
        Stopwatch s = new Stopwatch();
        s.start();

        int width  = drawWindow[1] - drawWindow[0];
        int height = drawWindow[3] - drawWindow[2];
  
        var img = createImageData(ctx, message, width, height);
        ProgressAnimation.stopAnimation();
        ctx.putImageData(img, drawWindow[0], drawWindow[2]);
        
        s.stop();
        print("Draw took : " + s.elapsedInMs());
      
      } catch (Exception e) {
        print("receive exception:" + e.toString());
      }
    });

    calcFrame(receivePort, fractParam); 
  }
}

void main() {
  Mandelbrot m = new Mandelbrot();
}