/**
 * @author Steffen Furholm
 */
import java.io.File;
import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

PImage source;
PImage destination;

int imgNum = 0;//13525;
String path = "6/img";
int firstImg = 13525;
int lastImg = 13635;
List<PImage> images = new ArrayList();

/**
 * Loads our initial image, sets up destination buffer for edge detector and sets the output window size. 
 */

void settings() {
  List<String> imagePaths = new ArrayList();

  for (File f : new File("/Users/jason/git/PegSlideDetector/newCameraMountCalibration").listFiles()) {
    if (f.getName().endsWith(".jpg")) {
      imagePaths.add(f.getAbsolutePath());
    }
  }
  if (imagePaths.size() > 100) {
    print("too many images!");
    exit();
  }
  Collections.sort(imagePaths);

  for (String path : imagePaths) {
    images.add(loadImage(path));
  }

  source = images.get(0);
  destination = createImage(source.width, source.height, RGB);
  size(source.width, source.height);
}


/**
 * Called repeatedly.
 * Performs edge detection on the source image, then generates a histogram of the region of interest
 * and overlays it on either the source image or the image containing the detected edges.
 */
void draw() {

  source = images.get(imgNum % (images.size()-1));
  background(0);  // Set black background

  // Camera wasn't aligned, so rotate the image a bit (a bit hacky, but it works)
  pushMatrix();
  rotate(radians(-5));
  image(source, 0, 0);
  source = get(); //returns a PImage containing the frame buffer of this PApplet
  popMatrix();

  // Load source image into .pixels array
  source.loadPixels();

  // Edge detection enhanced for vertical lines from source to destination
  float[][] matrix = { { -1, -1, -1 }, 
    { -1, 9, -1 }, 
    { -1, -1, -1 } }; 
  for (int x = 1; x < source.width-1; x++) {
    for (int y = 1; y < source.height-1; y++ ) {
      float sum = 0;
      for (int my = -1; my <= 1; my++) {
        for (int mx = -1; mx <= 1; mx++) {
          int pos = (y + my)*source.width + (x + mx);
          float val = red(source.pixels[pos]) + green(source.pixels[pos]) + blue(source.pixels[pos]);
          if (val > 180*3) {
            sum += matrix[my+1][mx+1] * val;
          }
        }
      }
      destination.pixels[y*source.width + x] = color(sum/3.0, sum/3.0, sum/3.0);
    }
  }  

  // We changed the pixels in destination
  destination.updatePixels();

  // Uncomment the following line to see the detected edges instead of the source image 
  //image(destination, 0, 0);

  // Clear histogram
  int[] histogram = new int[source.width];
  for (int x = 0; x < source.width; x++) {
    histogram[x] = 0;
  }

  // Generate histogram
  for (int y = source.height/2 - 30 -20; y < source.height/2 + 10 +20; y++) {
    for (int x = 0; x < source.width; x++) {
      int loc = x + y*source.width;

      int pixel = destination.pixels[loc];
      float r = red(pixel);
      float g = green(pixel);
      float b = blue(pixel);

      if (r + g + b > 10*3) {  // Make sure we've above some threshold
        histogram[x]+=r+g+b;
      }
    }
  }

  // Draw border around the region of interest
  color c = color(255, 0, 0);
  noFill();
  stroke(c);
  rect(0, source.height/2-30 -20, source.width-1, 40 +20);

  // Figure out what the max histogram value was
  int maxHistVal = 0;
  for (int x = 0; x < source.width; x++) {
    maxHistVal = max(maxHistVal, histogram[x]);
  }

  // Overlay histogram on image
  c = color(0, 255, 0);
  stroke(c);
  for (int x = 0; x < source.width; x++) {
    if ((float)histogram[x]/maxHistVal*20 > 15) {  // Make sure we've above some threshold
      line(x, source.height-1, x, source.height-1 - (float)histogram[x]/maxHistVal*20);
    }
  }
}

/**
 * Called whenever a key is pressed.
 * The next image will be loaded when pressing right arrow key, the previous when pressing left arrow key.
 */
void keyPressed() {
  if (key == CODED) {
    if (keyCode == RIGHT) {
      imgNum++;
    }
    if (keyCode == LEFT) {
      imgNum--;
    }
  }
}