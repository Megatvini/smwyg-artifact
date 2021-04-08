# smwyg-artifact

You would probably need to mount an external drive to generate BC samples and subsequently to generate `h5` datasets. You'd need at least `1 TB` disk space for all the files.
```
docker run -it -v /media/USER/EXTERNALDRIVE:/home/sip/paperback:rw --security-opt seccomp=unconfined af5324ff4674 bash

```
Then create symbolic links in the `eval` folder:
```
ln -s /home/sip/paperback/LABELED-BCs /home/sip/eval/LABELED-BCs
ln -s /home/sip/paperback/RESULTS-ML /home/sip/eval/RESULTS-ML

```
## Run the entire expriment
```bash
bash run-ml-experiment.sh
```

F-score results for each dataset are dumped in `RESULTS-ML/`

## Breakdown of the experiment

### Generate protected combinations from BC files (Mibench and Simple dataset) 
The protected samples are created from `mibench-cov` and `simple-cov` folders. 

> The `-cov` postfix indicates that coverage improver pass was ran on the plain BC files. 
coverage improver pass aims at improving the coverage of OH protection 
by cloning call-sites that have both input-dependent and input-independent execution path. 
This coverage improvment is not relevant for the ML project, 
it merely corresponds to OH protection and has been part of the repo from the beginning of OH development.

```bash 
bash generate-ml-files.sh
```
Note that this script can take up to an hour to complete depending on your machine's spec. 

Keep in mind that this script uses glpk ilp solver to compose protections. 
glpk fails to converge for large programs in a reasonable time. 
In our dataset, we have 6 programs that we classifed as large programs: 
`cjpeg.x.bc`,  `djpeg.x.bc`,  `say.x.bc`,  `susan.bc`,  `tetris.bc`, and `toast.x.bc`.
All of these programs are placed in the `mibench-6-cov` folder. 
Generating protected samples for these 6 instances requires using the experimental branch of composition framework and commercial solvers such as Gurobi. 


**TODO:** Add detailed steps for generating large samples.

### Extract structural features from protected programs 

```bash 
function waitforjobs {
        while test $(jobs -p | wc -w) -ge "$1"; do wait -n; done
}
function checkoutput {
        if [ $? -ne 0 ]; then
                echo $1 
                exit 1
        fi
}
for ds in 'simple-cov' 'mibench-cov'; do
        waitforjobs $(nproc)
        echo SPAWNING $(nproc) processes to generate CSV files from labled BC samples
        #echo bash ../program-dependence-graph/collect-seg-dataset-features.sh LABELED-BCs/$ds skip &
        #echo bash ../program-dependence-graph/collect-seg-dataset-features.sh LABELED-BCs/$ds skip &
        #echo bash ../program-dependence-graph/collect-seg-dataset-features.sh LABELED-BCs/$ds  skip &
        #echo bash ../program-dependence-graph/collect-seg-dataset-features.sh LABELED-BCs/$ds skip &
        bash ../program-dependence-graph/collect-seg-dataset-features.sh LABELED-BCs/$ds skip > /dev/null &
done
waitforjobs 1
checkoutput 'Failed to generate CSV files'
```

### Process extracted features and persist them as h5 datasets
```bash
for ds in 'simple-cov' 'mibench-cov'; do
        waitforjobs $(nproc)
        echo SPAWNING $(nproc) processes to generate H5 files from the CSV files
        bash ../sip-ml/ml-scripts/run-extractions.sh ../eval/LABELED-BCs/$ds/ RESULTS-ML/$ds &
done
waitforjobs 1
checkoutput 'Failed to generate H5 files'
```

### Machine learn data set
```bash 
for ds in 'simple-cov' 'mibench-cov'; do
        waitforjobs $(nproc)
        echo SPAWNING $(nproc) processes to train ML models 
        bash ../sip-ml/ml-scripts/run-predictions.sh RESULTS-ML/$ds/ &
done
waitforjobs 1
checkoutput 'Failed to finish localizations'

```

### Extract results
```bash
for ds in 'simple-cov' 'mibench-cov'; do
        echo DUMPING CSV result files in RESULTS-ML/$ds/
        python3 ../sip-ml/ml-scripts/dump-fscore-table.py RESULTS-ML/$ds/
done

checkoutput 'Failed to dump csv result files'
```
