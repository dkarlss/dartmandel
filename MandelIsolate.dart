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

class MandelIsolate extends Isolate {
  
  MandelIsolate();// : super.heavy(); since heavy isolates does not work in browser yet.
  
  double mandel(final double cr, final double ci, final int limit, final int iter) {
   
    double zr = 0.0;
    double zi = 0.0;
    double zr_tmp;
    int itercount = 0;
    double res;
    
    int sqlimit = limit * limit;
    
    do {
      zr_tmp = (zr * zr) - (zi * zi) + cr;
      zi = 2 * zr * zi + ci;
      zr = zr_tmp;         
                 
      if (itercount++ > iter) {
        break;
      }
      
      res = Math.pow(zr,2) + Math.pow(zi,2);

    } while (res < sqlimit); // Abort calculation quickly
    
    if (res.isNaN()) {
      return 1000000.0; // what ever ...
    }
    return Math.sqrt(res);
  }
  
  List<VPoint> calcRegion(final double x1, final double x2, final double y1, final double y2, final int dx1, final int dx2, final int dy1, final int dy2) {
    //print("Isolate:calcRegion (x1,x2):${x1} ${x2} (y1,y2):${y1} ${y2} (dx1,dx2):${dx1} ${dx2} (dy1,dy2):${dy1} ${dy2}");
    final int MAX_X = dx2-dx1;
    final int MAX_Y = dy2-dy1;
    
    double xstep =  (x2 - x1) / MAX_X;
    double ystep =  (y2 - y1) / MAX_Y;
    
    double xval = x1;
    double yval = y1;
    double res;
    
    final List<String> items = new List();
    
    List reslist = new List();
      
    for (int y = dy1; y < dy2; y+=1) {
      for (int x = dx1; x < dx2; x+=1) {
        res = mandel(xval,yval,10000,100);
               
        reslist.add(x);
        reslist.add(y);
        reslist.add(res);
        
        
        xval += xstep;
        
      }
      xval = x1;
      yval += ystep;
    }
   return reslist;
  }
  
  List<VPoint> calcRegionParam(FractParam f) {
    return calcRegion( f.x1, f.x2, f.y1, f.y2, f.dx1, f.dx2, f.dy1, f.dy2);
  }
  
  void main() {
    
    port.receive((List params, SendPort replyTo) {
      try {
        FractParam f = new FractParam(params[0],params[1],params[2],params[3],params[4],params[5],params[6],params[7]);
        var threadid = params[8];
        
        Stopwatch s = new Stopwatch();
        s.start();
        List result = calcRegionParam(f);
        
        s.stop();
        print("Isolate: calc region took:" + s.elapsedInMs());
        
        List sList = new List();
        
        //Send back drawing region.
        sList.add(params[4]);
        sList.add(params[5]);
        sList.add(params[6]);
        sList.add(params[7]);
        sList.add(params[8]);
        
        for (int i = 0; i < result.length; i+=3) {
          sList.add(result[i]);   // x
          sList.add(result[i+1]); // y
          sList.add(result[i+2]); // v
        }
        /**
        for (VPoint v in result) {
          sList.add(v.x);
          sList.add(v.y);
          sList.add(v.val);
        }*/
        
        replyTo.send(sList);
      } catch (Exception e) {
        print("Exception in IsolateMain: " + e.toString());
      }
    });
    
    
  }

}
