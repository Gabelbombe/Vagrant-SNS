## Test environment for Amazon Simple Email Service

If you are not using vagrant currently, please run installer script in scripts. Also please make sure you have the vbguest vagrant plugin installed (again, you can just run the installer)

#### Setting up the boxfile

From a terminal, `cd` to your cloned repo and run the following from its project root...

 * vagrant up
 * vagrant ssh

 `Please keep in mind that this requires a credentials in credentials/ses.csv to operate!`

From your browser visit this [local gateway](http://192.168.50.33)