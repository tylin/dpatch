This code is the authors' implementation of the algorithm described in:

Carl Doersch, Saurabh Singh, Abhinav Gupta, Josef Sivic, and Alexei A. Efros.
What Makes Paris Look like Paris? ACM Transactions on Graphics (SIGGRAPH
2012), August 2012, vol. 31, No. 3.

The core of the algorithm was written by Carl Doersch cdoersch at cs dot cmu
dot edu, and Saurabh Singh saurabh dot me at gmail dot com.  

This is unsupported research code; even if we do provide assistance, it will
only be if we are convinced you have made a serious attempt to run the code on 
your own.  We do, however, want this code to be useful, and so we welcome polite 
feedback on how to improve it.

General setup:

1) Install libsvm and edit the file 'myaddpath.m' so that it adds libsvm to the path.  

2) If you are not running 64-bit Linux, recompile features.cc and the code in MinMaxSelection/

cd hog
mex features.cc
cd ../MimMaxSelection/
make

3) Edit the file globalz.m such that res.root points to the directory
containing your data.  Unfortunately we cannot publicly distribute the data used
in the paper, since Google is subject some legal obligations with respect to
all Street View data.  Thus, the following sections can only explain how to 
format your data.

The code in this archive is set up to use data in some directory 
'/PATH/TO/ROOT/DIRECTORY/data7', that is served on the web at the url
'http://your.domain/WEB/ACCESSIBLE/PATH/data7/'.  This directory
contains a directory called 'cutouts' that contains the images to discover
elements in (data7 may contain other directories for downloaded panoramas, 
etc.).  The cutouts directory then has directories 'barcelona', 'boston', ... 
'tokyo', and each of these contains images from the cities (whose names start 
with GPS coordinates).  globalz.m contains an entry which points to the data7 
directory.  The file dataset7.mat included here will contain the correct 
metatata to describe the dataset.  loadimset(7) in autoclust_main.m will
then automatically load dataset7.mat and you will be ready to run the code.

3.1) If you want to use your own data, use the function setdataset.m.  

setdataset(imgs, datadir, weburl):

datadir is the root directory containing all of your images, and weburl is a
url pointing to the same data hosted on the web. imgs a struct array of metadata that will let
this code find each image. dataset7.mat contains an example of such a struct array.
Each element of the array must contain the following fields:

 - fullname: a path relative to the root such that [datadir imgs(i).fullpath]
   is an absolute path to the i'th image.  Similarly, [weburl
   imgs(i).fullpath] is a url for that image.
 - city: a city label describing where the image came from.  It's optional but
   it's used in displays.
 - imsize: an array specifying the size of the image, of the form [rows
   columns].

Use the setdataset function in place of loadimset; they accomplish the same
task.

3.2) If you want to download data from streetview, you need to use the
scripts in the GSwDownloader folder.  First, create a download directory;
we will call it downloaddir.  Next, open streetview_panoid.html in a
web browser.  It is currently configured to scrape data from the cities used
in the paper; the "cityname" "citylat" and "citylng" variables let you control
where the data comes from.  This page displays the contents of two files:
download.txt and mapping.txt.  Create a file mapping.txt in the downloaddir
and copy the displayed contents into it; likewise for download.txt.  Choose a
set number (we'll call it setno).  Next,
edit globalz.m to produce a struct with the following fields when
globalz(setno) is called:

 - downloaddir: the directory containing download.txt and mapping.txt; it will
   be used to store panoramas and other files as well.
 - cutoutdir: the final directory where all of the cutouts will be placed; it
   can be a subdirectory of downloaddir.  It corresponds to datadir from
   section 3.2.
 - imgsurl: a URL pointing to the same data as in cutoutdir, hosted on the
   web.  It corresponds to weburl from section 3.2
 - datasetname: a file (path is relative to matlab's working directory)
   that will contain the final dataset descriptor (the discriptor is the
   ('imgs' from section 3.2).

Next, edit the file streetview_download.m, changing the call globalz(7) to
globalz(setno).  Optionally reconfigure the parameters passed to dsmapredopen
to use a different number of workers, or distributed processing if it's
enabled (I have found that Street View will handle 50 or more processors
simultaneously making requests).  Finally, start matlab in the same directory
that contains this file, run myaddpath and then streetview_download.  

4) Actually run the clustering code.  The main script is autoclust_main.m.
Edit it so that it specifies the correct dataset, either with globalz(setno) or
with setdataset.  Pass the name of an output directory to dssetout, and set
ds.dispoutpath to point to a directory that's
visible over the web, or remove the declaration of the variable to output the
html displays within the main output directory.  Optionally reconfigure 
the parameters passed to
dsmapredopen.  Run the file by starting matlab and running autoclust_main;
this "main" thread will automatically start "worker" threads, either locally
or distributed.  For the experiments in the paper, I found that each worker 
thread required less than 2GB of memory, and the main job required less than 
16GB of memory (though the majority of that usage seems to be due to matlab's 
internal memory leaks; if these leaks were fixed the main job would probably 
use less than 4GB.  In practice, total leaked memory increases with each 
round of training).

The algorithm produces several outputs in dispoutpath (or in the ds root if
it's not specified).  These pages may contain tens of thousands of images;
make sure you have plenty of memory available before opening them.  We suggest 
Firefox for viewing, as Chrome often fails to load all the images on some pages.bestbin0/bbhtml.html shows a sampling of the
initial patches (before deduplication).  bestbin_topn/allcandidateshtml.html 
shows the candidates that were chosen after deduplication to undergo
refinement.  bestbin_topn/bbhtml[]/X.html shows the algorithm's progress
on each of the refined candidates, 20 per page with an ordering that follows
allcandidateshtml.html.  These pages are built as the
algorithm progresses. bestbin_overallcounts/bbhtml.html and 
bestbin_posterior/bbhtml.html show the final outputs of the algorithm ranked 
in different ways (see autoclust_main.m for details)
