#
# Script.ps1
#

Send-MailMessage -SmtpServer 'silversmtp.silversands.co.uk' -To 'jamie.sayer@silversands.co.uk' -Subject 'Test' -Body 'Test!' -From 'simon.robinson@silversands.co.uk'