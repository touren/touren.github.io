---
layout: post
title: Create a cloud video streaming MVP with Kurento
description: An example of building your first video streaming Minimum Viable Product(MVP).
tags: 
    - Kurento
    - Live Streaming
    - OpenCV
    - OCR
    - MVP
---

# Create a cloud video streaming MVP with Kurento

With [WebRTC](https://webrtc.org/) technology, people can easily stream their live video and audio content just using a web browser. If you have a cloud video streaming idea and want to build a **Minimum Viable Product**(MVP), [Kurento](https://www.kurento.org/) is the choice. With Kurento, you’d be able to handle the streaming audio/video easily, including analyzing, mixing, augmentation, etc. Kurento is a WebRTC server infrastructure, based on gstreamer. With its seamless [OpenCV](http://opencv.org/) integration, you can process the video frame by frame quite handily. Kurento now is a developing project and updates very often, so fasten your seatbelt. I am trying to show you how Kurento works by a simple demo program: license plate detector. 

## Let’s get our hands dirty

To run the demo program: license plate detector, all we need are an Ubuntu box and a web browser.(OK, not any browser, just Chrome, Firefox or Opera.)

Install kurento server on the Ubuntu box:
```
echo "deb[ http://ubuntu.kurento.org](http://ubuntu.kurento.org/) trusty-dev kms6" | sudo tee /etc/apt/sources.list.d/kurento-dev.list
wget -O -[ http://ubuntu.kurento.org/kurento.gpg.key](http://ubuntu.kurento.org/kurento.gpg.key) | sudo apt-key add -
sudo apt-get update
sudo apt-get install kurento-media-server-6.0-dev
sudo apt-get install kms-platedetector-6.0
sudo apt-get install libboost-all-dev libjson-glib-dev bison flex uuid-dev libsoup2.4-dev build-essential libtool autotools-dev  automake git libtesseract-dev
sudo service kurento-media-server-6.0 start
```

Install kurento tutorial nodejs on the Ubuntu box:

```
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs
sudo npm install npm -g
git clone [https://github.com/Kurento/kurento-tutorial-js.git](https://github.com/Kurento/kurento-tutorial-js.git)
cd kurento-tutorial-js/kurento-platedetector
http-server -p 8443 -S -C keys/server.crt -K keys/server.key
npm install
npm start
```

Open link [https://localhost:8443](https://localhost:8443) in web browser and check the result:

![image alt text](/assets/images/mvp_with_kurento/image_0.png)

Hmmm, not so accurate, but it does work.

![image alt text](/assets/images/mvp_with_kurento/image_1.png) ⇒  ![image alt text](/assets/images/mvp_with_kurento/image_2.png)

## Close-up

Let’s dip into the source project to see how that works. Pull the project from github and build it.

```
git clone https://github.com/Kurento/kms-platedetector.git
cd kms-platedetector/src
cmake ..
make
```
There are two folders: kms-platedetector/src

gst-plugins/		implements a **gstreamer plugin**: platedetector

server/			implements a **kurento plugin**: PlateDetectorFilter

The Kurento server is controlled by web browser using Kurento Protocol, based on WebSocket and JSON-RPC. The **kurento plugin** is the interface of the protocol, it receives the remote call from web browser and creates a **gstreamer plugin** to do the real job, i.e. analyze every frame from the live video stream, find where the plate locate, and recognize the numbers and characters.

The Kurento Server will do the WebRTC stuff for you, so you don’t need to worry about the details of stream encode/decode, NAT traversal, which are really, really fuzzy.

![image alt text](/assets/images/mvp_with_kurento/image_3.png)

Kurento provides a tool to create the above plugin structure, which is kurento-module-scaffold. You can use this tool to create two flavors of Kurento modules:

1. OpenCV module:

kurento-module-scaffold.sh <module_name> <output_directory> opencv_filter

2. Gstreamer module:

	kurento-module-scaffold.sh <module_name> <output_directory>

Kurento is based on two concepts that act as building blocks for application developers:

* **Media Elements.** A Media element is a functional unit performing a specific action on a media stream. Media elements are a way of every capability is represented as a self-contained "black box" (the media element) to the application developer, who does not need to understand the low-level details of the element for using it. Media elements are capable of receiving media from other elements (through media sources) and of sending media to other elements (through media sinks). Depending on their function, media elements can be split into different groups:

    * **Input Endpoints:** Media elements capable of receiving media and injecting it into a pipeline. There are several types of input endpoints. File input endpoints take the media from a file, Network input endpoints take the media from the network, and Capture input endpoints are capable of capturing the media stream directly from a camera or other kind of hardware resource.

    * **Filters:** Media elements in charge of transforming or analyzing media. Hence there are filters for performing operations such as mixing, muxing, analyzing, augmenting, etc.

    * **Hubs:** Media Objects in charge of managing multiple media flows in a pipeline. A Hub has several hub ports where other media elements are connected. Depending on the Hub type, there are different ways to control the media. For example, there are a Hub called Composite that merge all input video streams in a unique output video stream with all inputs in a grid.

    * **Output Endpoints:** Media elements capable of taking a media stream out of the pipeline. Again, there are several types of output endpoints specialized in files, network, screen, etc.

* **Media Pipeline**: A Media Pipeline is a chain of media elements, where the output stream generated by one element (source) is fed into one or more other elements input streams (sinks). Hence, the pipeline represents a "machine" capable of performing a sequence of operations over a stream.

You can regard the OpenCV module and Gstreamer module as **Filters** that you need to implement. **Media Pipeline** and other **Media Elements** are already implemented by Kurento. More details [here](http://doc-kurento.readthedocs.io/en/stable/mastering/kurento_API.html).

Kurento use GStreamer to do the real streaming media job. Actually, Kurento Server is a gstreamer session manager, maintaining a bunch of gstreamer pipelines. In order to understand how kms-platedetector plugin works, we have to look deep into GStreamer.

GStreamer is a framework for creating streaming media applications. The fundamental design comes from the video pipeline at Oregon Graduate Institute, as well as some ideas from DirectShow.

The GStreamer framework is designed to make it easy to write applications that handle audio or video or both. The pipeline design is made to have little overhead above what the applied filters induce. This makes GStreamer a good framework for designing even high-end audio applications which put high demands on latency.

![image alt text](/assets/images/mvp_with_kurento/image_4.png)

Many of the virtues of the GStreamer framework come from its modularity: GStreamer can seamlessly incorporate new plugin modules. But because modularity and power often come at a cost of greater complexity, writing new applications is not always easy.

Kurento Server is one of the gstreamer tools, which means you can use any plugins it includes, or you could create a new one based on these off-the-shelf. Most of them are open source and you can customize them to fit your specified requirement, if you can find one. More importantly, Kurento has done most of the difficult part of GStreamer framework for you, so all you need are writing the code into the plugin structure kurento-module-scaffold created for you. Of course, understanding the [GStreamer’s basic concepts](https://gstreamer.freedesktop.org/data/doc/gstreamer/head/manual/html/index.html) will help you do a better and easier job. 

Now, let’s take a look at the functions(in gst-plugins/platedetector/kmsplatedetector.c) you mostly need to implement:

**static void class_init ()**

It’s the function called when a plugin first created, and usually do some class initialization jobs like installing some override methods, such as getter/setter, finalize/dispose, adding pad template, registering private structure, etc.

![image alt text](/assets/images/mvp_with_kurento/image_5.png)

**static void init ()**

It’s the function called every time a plugin created, and usually do some object initialization jobs like setting default value to plugin’s parameters, creating other resources, such as plugins, files, fonts, etc.

![image alt text](/assets/images/mvp_with_kurento/image_6.png)

**static GstFlowReturn transform_frame_ip (GstVideoFilter *filter, GstVideoFrame *frame)**

It’s the function called every time a new frame comes, and usually do some image operation like analyzing the incoming frame, drawing something on it, mixing other input frames into one, etc.

![image alt text](/assets/images/mvp_with_kurento/image_7.png)

This is the most important function you need to handle, but the incoming frame is presented as GstVideoFrame, which is not so easy to deal with, unless you really fancy the bitwise operations. Here comes OpenCV, which is a convenient tool to process the image with its rich computer vision and machine learning algorithms, and it’s straightforward and no-performance-cost to transform GstVideoFrame to Image objects, like Mat, IplImage, in OpenCV.

## The End

Using Kurento, you can build a MVP to verify your video cloud streaming idea quickly, although the performance of Kurento is still an issue. Since Kurento is under developing, if you don’t make a good backup of the current version, your project may not compile at all after updating to a new version of Kurento.

Some tips for developing Kurento applications:

* Backup the version of Kurento you are working on, because the Kurento develop team don’t do that for you.

* Debug your Kurento application using the runtime pipeline map. If you have some problem, try to dump the pipeline runtime to a dot file and check it out. e.g.

```
presenter.pipeline.getGstreamerDot(function(err, ret){

        var fs = require('fs');

        fs.writeFile("pipeline.dot", ret, function(err) {

                console.log("The file pipeline.dot was saved!");

        });

});
```

![image alt text](/assets/images/mvp_with_kurento/image_8.png)

* Find a similarly plugin first before you want to create a new one, because there are plenty of open source plugin there, even you can not find a suitable one, you can learn something from these source code.

Let me know if you use Kurento and how it goes for you!


