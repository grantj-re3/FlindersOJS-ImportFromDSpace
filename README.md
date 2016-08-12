# FlindersOJS-ImportFromDSpace

A tool for transforming a collection of DSpace Simple Archive Format (SAF)
items into a "collection" of articles suitable for bulk importing into the
Open Journal Systems (OJS) application.


## dspace_saf2ojs_wrap.sh tool

Below is an example of dspace_saf2ojs_wrap.sh usage.

### On the DSpace server

- Clone the github repo
```
$ git clone https://github.com/grantj-re3/FlindersOJS-ImportFromDSpace.git OJS-ImportFromDSpace
```

- Edit any fields in the wrapper XML
```
cd OJS-ImportFromDSpace/etc
vim dspace_saf2ojs_begin.xml	# Use your favourite editor
```

- Export the DSpace collection in Simple Archive Format
```
$ cd ../results
$ mkdir MyCollection            # Replace MyCollection with your own collection name
$ ~/dspace/bin/dspace export -t COLLECTION  -i 123456789/3214 -d MyCollection -n 10001
```

- Create results/ojs_import.xml with pointers to PDFs at results/MyCollection/*/*.pdf
```
# Use symlink as dspace_saf2ojs_wrap.sh expects the folder results/dspace_saf
$ ln -s MyCollection dspace_saf
$ ../bin/dspace_saf2ojs_wrap.sh
```

- Create a tarball ready for copying to the OJS server
```
$ cd ..
$ tar cvzf OJS-ImportFromDSpace-results160805a.tgz results
```

- Copy the tarball to OJS server.

### On the OJS server

- Unzip the tarball
```
$ cd /to/my/dir
$ tar zxvpf OJS-ImportFromDSpace-results160805a.tgz
```

- Import ojs_import.xml into the "test1" journal (as user admin)
```
$ cd results
$ php ~/public_html/tools/importExport.php NativeImportExportPlugin import ojs_import.xml test1 admin
```

- Celebrate!

## Environment

This software has been used in the following environment.

### DSpace [production]

Operating System:
- Red Hat Enterprise Linux Server release 6.8 (Santiago)
- Linux 2.6.32-573.22.1.el6.x86_64 #1 SMP Thu Mar 17 03:23:39 EDT 2016 x86_64 x86_64 x86_64 GNU/Linux

DSpace:
- DSpace 3.1

dspace_saf2ojs_wrap.sh:
- GNU bash, version 4.1.2(1)-release (x86_64-redhat-linux-gnu)
- xsltproc was compiled against libxml 20706, libxslt 10126 and libexslt 815
- xmllint: using libxml version 20706
- ruby 1.8.7 (2013-06-27 patchlevel 374) [x86_64-linux]

### Open Journal Systems (OJS) [non-production]

Operating System:
- CentOS release 6.8 (Final)
- Linux 2.6.32-573.8.1.el6.x86_64 #1 SMP Tue Nov 10 18:01:38 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux

OJS:
- Open Journal Systems 2.4.8.0
- PHP 5.4.45 (cli) (built: Oct  5 2015 14:16:21)

