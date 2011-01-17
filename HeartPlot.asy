// HeartPlot.asy V0.5, an asymptote script to plot data from the heart spark
// (c) Sensebridge.net
// Released under cc-sa-nc license

import graph;

// load config stuff from stdin (put there by the shell script)
string[] args=stdin.line().csv();

string filename = args[0];
string title = "Heart Spark: " + args[1];
real xstart = (real)args[2]; // x-axis start value
real xstop = (real)args[3];  // x-axis stop value
real ystart = (real)args[4]; // y-axis start value
real ystop = (real)args[5];  // y-axis stop value
real dotsize = (real)args[6]; // dot size: 1 is very big, 0.1 is very small
bool FilteringOn = (int)args[7] != 0; // enable data filtering?

size(7.5inch,5inch,IgnoreAspect);  // this is good for PDFs

//size(8.5inch, 11inch, IgnoreAspect); // this size seems to be the only
		// one that works for .png output, and even then it's
		// crappy: only 612x792... with transparent background!

//string data="HeartData_WholeDay_2011Jan14.csv";
//file in=input(data).line().csv();

file in=input(filename).line().csv();

string[] prettytitle=in;
string[] versionnumbers=in;
string[] HSdate=in;
string[] computerdate=in;
string[] columnlabel=in;
string[] crap=in;

string[][] a=in.dimension(0,0);
a=transpose(a);
real[] unixepoch=(real[])a[0], minutes=(real[])a[1], heartrate=(real[])a[2];

int numpoints = minutes.length;
real rollingaverage = 75;

bool FilterPoint(int i)
{
  if (FilteringOn)
{
  real LowerBound = 0.60;
  real UpperBound = 1.30;

  // filter and plot the point
  if (i > 2 && i < (numpoints-2))
  {
    if (heartrate[i] < LowerBound*heartrate[i-1])
    {  // our data is "probably" a false negative, i.e.	we missed a point
       if (heartrate[i]*2 < 1.15*rollingaverage)
       {
         heartrate[i] = heartrate[i]*2;
         // we could also plot a SECOND point for the one we missed
         // but I am content to just plot this one at the "average" of the
         // two beats that would be here..
       }
       else
       {
         // hmm, it shouldn't be so high like that, maybe it's not a false
         // negative, let's just plot it normally
       }         
    }
    else if (heartrate[i] > UpperBound*heartrate[i-1] && heartrate[i] > 0.8*rollingaverage)
    { // we've got a potential false positive.  But let's check
      // carefully, because sometimes heartrate really does jump up quickly
      // check: if the total time of i and i+1 beats is similar to time
      // of i-1th beat, i is probably a false postive, we shouldn't plot it
      // and we should modify it and i+1 so that i+1 will plot "correctly"
      if (abs((minutes[i+1]-minutes[i-1])/(minutes[i-1]-minutes[i-2])-1)<0.15)
      {  // it has passed the test, both beats are with 15% of the time of
         // the previous beat, so it's likely a false positive
         real backup = heartrate[i+1];
         heartrate[i+1] = (int)(1.0/(minutes[i+1]-minutes[i-1]));
         if (heartrate[i+1] > 1.15*rollingaverage || heartrate[i+1] < 0.85*rollingaverage)
	 {  // then bail or something, hell if I know!
	 } 
	 heartrate[i] = heartrate[i-1];  // ensure filtering doesn't trigger
         // and DO NOT PLOT point i: point i+1 will be plotted soon. 
         return false;
      }
    }
    else
    {
      // just plot as normal
    }

  }
  else
  { // just plot it, we don't have enough data around this point to filter
  }

  rollingaverage = rollingaverage*0.90 + 0.10*heartrate[i];
} // end if filtering on
  return true;
}

defaultpen(dotsize);

// Iterate over our data array and plot it
for(int i=0;i<numpoints;++i) {
  if (minutes[i] >= xstart && minutes[i]<=xstop) {
    if (heartrate[i] >= ystart && heartrate[i] <= ystop){
      if (FilterPoint(i))
      {
        pair point=(minutes[i], heartrate[i]);
        dot(point);
      }
    }
  }
}
// if we asked for way too much, set xstop to highest real data point
// note that this assumes data points are in temporal order !!!
if (xstop > minutes[numpoints-1]) xstop = ceil(minutes[numpoints-1]);

// draw invisible dots at the far corners, otherwise the corner labels
// do not work (annoying!)
dot((xstart,ystart), invisible);
dot((xstop, ystop), invisible);

xaxis("Time (minutes)",BottomTop,LeftTicks);
labelx(currentpicture,"",(xstart,ystart));
labelx(currentpicture,"",(xstop,ystart));
labely(currentpicture,"",(xstart,ystart));
labely(currentpicture,"",(xstart,ystop));
yaxis("Heart Rate (BPM)",Left,RightTicks);
yaxis(Right);

scale(true);

// add graph title.  Note: would be cool to center it based on
// length of title, or automatically, but not sure how to do that...
label(shift(2inch*E+5mm*N)*title, point(NW),E);
