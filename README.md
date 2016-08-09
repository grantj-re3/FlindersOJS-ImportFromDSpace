# FlindersOJS-ImportFromDSpace

A tool for transforming a collection of DSpace Simple Archive Format (SAF)
items into a "collection" of articles suitable for bulk importing into the
Open Journal Systems (OJS) application.


## dspace_saf2ojs_wrap.sh

Below is an example usage.

- On the DSpace server:

```
# Clone the github repo
$ git clone https://github.com/grantj-re3/FlindersOJS-ImportFromDSpace.git OJS-ImportFromDSpace

# Edit any fields in the wrapper XML
cd OJS-ImportFromDSpace
cd etc
vim dspace_saf2ojs_begin.xml	# Use your favourite editor

# Export the DSpace collection
$ cd ../results
$ mkdir MyCollection            # Replace MyCollection with your own collection name
$ ~/dspace/bin/dspace export -t COLLECTION  -i 123456789/3214 -d MyCollection -n 10001

# Create results/ojs_import.xml with pointers to PDFs at results/MyCollection/*/*.pdf
$ ln -s MyCollection dspace_saf
$ ../bin/dspace_saf2ojs_wrap.sh

# Create a tarball ready for copying to the OJS server
$ cd ..
$ tar cvzf OJS-ImportFromDSpace-results160805a.tgz results
```

- Move the tarball to OJS server.

- On the OJS server:

```
# Unzip the tarball
$ cd /to/my/dir
$ tar zxvpf OJS-ImportFromDSpace-results160805a.tgz

# Import ojs_import.xml into the "test1" journal (as user admin)
$ cd results
$ php ~/public_html/tools/importExport.php NativeImportExportPlugin import ojs_import.xml test1 admin
```

- Celebrate!

