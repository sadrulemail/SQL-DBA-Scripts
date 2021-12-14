#variables
$emailFrom = "DCA-T-APP02@wcgclinical.com"
$emailTo = "salom@medavante.com,fhossain@wcgclinical.com"
$subject = "DBA test SMTP server"
$body = "Send an email through SMTP in Powershell"
$smtpServer = "irismail.wirb.com"

#create a function

Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer)
{
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom,$emailTo,$subject,$body)
}

#call the function
sendEmail $emailFrom $emailTo $subject $body $smtpServer