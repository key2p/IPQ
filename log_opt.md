sed -i '/SystemMaxUse/d' /etc/systemd/journald.conf
sed -i '/MaxRetentionSec/d' /etc/systemd/journald.conf
sed -i '/MaxFileSec/d' /etc/systemd/journald.conf

echo 'SystemMaxUse=1G' >> /etc/systemd/journald.conf
echo 'MaxRetentionSec=15day' >> /etc/systemd/journald.conf
echo 'MaxFileSec=1month' >> /etc/systemd/journald.conf

sed -i '/weekly/d' /etc/logrotate.d/rsyslog
sed -i '/rotate /d' /etc/logrotate.d/rsyslog

sed -i 's/weekly/daily/g' /etc/logrotate.d/rsyslog
sed -i '/daily/i\\trotate 30' /etc/logrotate.d/rsyslog
