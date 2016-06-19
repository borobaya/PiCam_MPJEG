# PiCam_MPJEG

A minimum working implementation of the video feed from the Rasberry Pi camera
being displayed on iOS devices. Specifically, the MJPEG stream from the uv4l package.

## Raspberry Pi

On the Raspberry Pi, the uv4l camera driver needs to be installed:

```shell
wget http://www.linux-projects.org/listing/uv4l_repo/lrkey.asc && sudo apt-key add ./lrkey.asc  
echo "deb http://www.linux-projects.org/listing/uv4l_repo/raspbian/ wheezy main" | sudo tee -a /etc/apt/sources.list  
sudo apt-get update  
sudo apt-get install uv4l uv4l-raspicam uv4l-raspicam-extras uv4l-server uv4l-uvc uv4l-xscreen uv4l-mjpegstream  
sodu reboot
```

For more information on setting up the Raspberry Pi Camera, check out
http://www.home-automation-community.com/surveillance-with-raspberry-pi-noir-camera-howto/

## Issues

This implementation uses one deprecated iOS library, `NSURLConnection` to connect
to the stream. Use of the newer `NSURLSession` alse exists but causes flickering of
the video.

The flickering has something to do with updating the image synchronously with the
main thread, and/or the image being rendered and drawn on the main thread. If you
have a solution to this please do let me know! :)

## Tips

In case the camera fails to turn off after disconnecting from it, restart the
uv4l-server on the Raspberry Pi using:

```shell
sudo service uv4l_raspicam restart
```
