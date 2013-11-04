/*=========================================
 VIDEO TO DP CONVERSION PROGRAM
 Rayce Stipanovich
 =========================================*/
 
import java.util.Calendar;
import java.text.SimpleDateFormat;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import controlP5.*;
import hypermedia.net.*;
import processing.video.*;

int resample_x_start = 0;
int resample_x_end = width;
int resample_y_start = 0;
int resample_y_end = height;

UDP udp;
Capture cam;

byte[][][] pixelFrame = new byte[16][16][3];
PImage bufferedImage;

String ip       = "130.215.173.217";  // the remote IP address
int port        = 6100;    // the destinat

void writeArray() {
  String message = new String("");

  for (int y = 0; y< 16; y++) {
      for (int x = 0; x < 16 ; x++ ) {
        byte tempframe = 0x00;
        tempframe += ((pixelFrame[x][y][0] & 0xE0) >> 1);
        tempframe += ((pixelFrame[x][y][1] & 0xC0) >> 4);
        tempframe += ((pixelFrame[x][y][2] & 0xC0) >> 6);
        message += Byte.toString(tempframe);
      }
    }
  udp.send(message, ip, port );
}

public void setup() {
  size(640, 480);
  frameRate(30);
  udp = new UDP( this, 6000 );
  String[] cameras = Capture.list();
  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, 640, 480);
  } if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, cameras[1]);
    cam.start();
  }
}

public void draw() {
  bufferedImage = createImage(16, 16, RGB);
  if (cam.available() == true) {
    cam.read();
    cam.loadPixels();
    
    resample_x_end = cam.width-1;
    resample_y_end = cam.height-1;
    
    int xdist = (resample_x_end - resample_x_start + 1)/16;
    int ydist = (resample_y_end - resample_y_start + 1)/16;
    int xoffset = resample_x_start + xdist/2;
    int yoffset = resample_y_start + ydist/2;
    
    //perform multipoint sampling
    for (int y = 0; y < 16; y++) {
      for (int x = 0; x < 16; x++) {
        // Calculate the adjacent pixel for this kernel point
        int pos = (yoffset + y*ydist)*cam.width + (xoffset + x*xdist);
        
        //red gets 3 bits
        //greena nd blue get 2 bits
        pixelFrame[x][y][0] = (byte)((((short)red(cam.pixels[pos]) >> 5) & 0x07) << 5);
        pixelFrame[x][y][1] = (byte)((((short)green(cam.pixels[pos]) >> 6) & 0x03) << 6);
        pixelFrame[x][y][2] = (byte)((((short)blue(cam.pixels[pos]) >> 6) & 0x03) << 6);
      }
    }
    image(cam, 0, 0);
    for (int y = 0; y < 16; y++) {
      for (int x = 0; x < 16; x++) {
        bufferedImage.pixels[y*16 + x] = color((short)(pixelFrame[x][y][0] & 0xff), (short)(pixelFrame[x][y][1] & 0xff), (short)(pixelFrame[x][y][2] & 0xff));
      }
    }
  }
  bufferedImage.updatePixels();
  image(bufferedImage, 320, 60, 160, 160);
  
  writeArray();
}

