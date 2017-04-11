module m_bmp {
  record t_bmp_file_header {
    var bfType      : int(16) = 19778; //"BM"
    var bfSize      : int(32);
    var bfReserved1 : int(16) = 0;
    var bfReserved2 : int(16) = 0;
    var bfOffBits   : int(32);
  }

  record t_bmp_info_header {
    var biSize          : int(32) = 40; // Z'28'
    var biWidth         : int(32);
    var biHeight        : int(32);
    var biPlanes        : int(16) = 1;  // always 1
    var biBitCount      : int(16);
    var biCompression   : int(32) = 0;  // 0:nocompression 
    var biSizeImage     : int(32);
    var biXPelsPerMeter : int(32) = 3780; // 96 dpi
    var biYPelsPerMeter : int(32) = 3780; // 96 dpi
    var biClrUsed       : int(32) = 0;
    var biClrImportant  : int(32) = 0; 
  }

  record t_rgb {
    var b, g, r : uint(8);
  }

  class t_bmp {
    var D: domain(2);
    var file_header: t_bmp_file_header;
    var info_header: t_bmp_info_header;
    var rgb: [D] t_rgb; 

    proc wr(fn:string) {
      var f = open(fn, iomode.cw);
      var w = f.writer(kind=ionative);
      var nx: int(32) = this.D.high(1):int(32);
      var ny: int(32) = this.D.high(2):int(32);

      this.file_header.bfSize      = 14 + 40 + 0 + nx * ny * 3;
      this.file_header.bfOffBits   = 14 + 40;
      this.info_header.biWidth     = nx;
      this.info_header.biHeight    = ny;
      this.info_header.biBitCount  = 24;
      this.info_header.biSizeImage = nx * ny * 3;

      w.write(this.file_header.bfType         );
      w.write(this.file_header.bfSize         );
      w.write(this.file_header.bfReserved1    );
      w.write(this.file_header.bfReserved2    );
      w.write(this.file_header.bfOffBits      );

      w.write(this.info_header.biSize         );
      w.write(this.info_header.biWidth        );
      w.write(this.info_header.biHeight       );
      w.write(this.info_header.biPlanes       );
      w.write(this.info_header.biBitCount     );
      w.write(this.info_header.biCompression  );
      w.write(this.info_header.biSizeImage    );
      w.write(this.info_header.biXPelsPerMeter);
      w.write(this.info_header.biYPelsPerMeter);
      w.write(this.info_header.biClrUsed      );
      w.write(this.info_header.biClrImportant );

      for j in D.dim(2) do
        for i in D.dim(1) do
          w.write(this.rgb(i, j).b, this.rgb(i, j).g, this.rgb(i, j).r);
      w.close();  
    }

    proc point(x, y) {
       var ix: int = x:int, iy: int = y:int;
       this.rgb(x:int, iy + 1).g = 255:uint(8);
    }
  }
}

module fern {
  use Random;
  use m_bmp;

  config const n: int = 20, nx: int = 500, ny: int = 500;
  const D = {1..nx, 1..ny};
  var bmp = new t_bmp(D);

  proc w1x(x, y) return  0.836 * x + 0.044 * y        ;
  proc w1y(x, y) return -0.044 * x + 0.836 * y + 0.169;
  proc w2x(x, y) return -0.141 * x + 0.302 * y        ;
  proc w2y(x, y) return  0.302 * x + 0.141 * y + 0.127;
  proc w3x(x, y) return  0.141 * x - 0.302 * y        ;
  proc w3y(x, y) return  0.302 * x + 0.141 * y + 0.169;
  proc w4x(x, y) return  0.0                          ;
  proc w4y(x, y) return              0.175 * y        ;

  proc f(k:int, x, y) {
    var r: [0..0] real;
    if (k > 0) {
      f(k - 1, w1x(x, y), w1y(x, y));
      fillRandom(r);
      if r(0) < 0.3 then f(k - 1, w2x(x, y), w2y(x, y));
      fillRandom(r);
      if r(0) < 0.3 then f(k - 1, w3x(x, y), w3y(x, y));
      fillRandom(r);
      if r(0) < 0.3 then f(k - 1, w4x(x, y), w4y(x, y));
    }
    else
      bmp.point(x * nx * 0.98 + 0.5 * nx, y * ny * 0.98);
    }

  proc main() {
    f(n, 0.0, 0.0);    
    bmp.wr("fern.bmp"); 
  }
}