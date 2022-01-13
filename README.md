# GmailAuthSMTP
This project is a very basic demo showing how to authenticate with OAUTH2 and send an email message for gmail as well as hotmail.com/outlook.com/live.com email addresses.

You will need to create a file called Globals.pas which contains the following constants

* google_clientid
* google_clientsecret
To get these, go to https://console.cloud.google.com/apis/credentials

* google_clientaccount

* microsoft_clientid
* microsoft_clientaccount
To get these, go to https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade

* clientsendtoaddress
* clientname

With some further work, this could be further improved to remove some of the required constants and improving some of the error handling.

At this stage, the refresh_tokens are retrieved in the authentication process - but are not saved.  If these were saved, the process would not require a web browser everytime to authenticate.



Thanks

Geoffrey Smith

My Notes:
Please notice The new Data Module. its easy to call from any gui.
You can build the adapter to send the Subject Body and other email parameters. even Attachment is implemented, for one document.
The Encrypyion bridge is a stub, you must roll your own. 
If you are planning on saving the Token in ini file.

