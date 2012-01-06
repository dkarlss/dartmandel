class Utils {

  /**
   * HSV to rgb from: http://www.cs.rit.edu/~ncs/color/t_convert.html
  */
  static List hsv(num h, num s, num v) {
    var r, g, b;
    int i;
    var f,p,q,t; 
    
    if (s == 0){
        r = g = b = v;
        return [(r * 255).toInt(),(g * 255).toInt(), (b * 255).toInt()];
    }
   
    h /= 60;
    i  = h.toInt();
    f = h - i;
    p = v *  (1 - s);
    q = v * (1 - s * f);
    t = v * (1 - s * (1 - f));
   
    switch( i ) {
        case 0:
            r = v;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = v;
            b = p;
            break;
        case 2:
            r = p;
            g = v;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = v;
            break;
        case 4:
            r = t;
            g = p;
            b = v;
            break;
        default:        // case 5:
            r = v;
            g = p;
            b = q;
            break;
    }
    return [(r * 255).toInt(), (g * 255).toInt(), (b * 255).toInt()];
}
}