# smwyg-artifact

You would probably need to mount an external drive to generate BC samples and subsequently to generate `h5` datasets. You'd need at least `1 TB` disk space for all the files.
```
docker run -it -v /media/USER/EXTERNALDRIVE:/home/sip/paperback:rw --security-opt seccomp=unconfined d8be09bc6a02 bash

```
Then create symbolic links in the `eval` folder:
```
ln -s /home/sip/paperback/LABELED-BCs /home/sip/eval/LABELED-BCs
ln -s /home/sip/paperback/RESULTS-ML /home/sip/eval/RESULTS-ML

```
