#!/bin/bash

ip=$1

if [ -z $ip ]; then
  echo '我们需要 docker daemon 或虚拟机的 ip 地址来生成 host 内容'
  exit 1
fi

output_file=served_hosts.txt
start_pattern='Sanjieke Dev Domains'
end_pattern='GoodMorningSir'

echo "# ${start_pattern}" > $output_file

for i in `grep -h server_name nginx/sites-enabled/*.conf | sed 's/[\	\ ]*server_name[\	\ ]*//g' | sed 's/;//g'`; do
  echo "${ip} ${i}" >> $output_file
done

echo "# ${end_pattern}" >> $output_file

echo "${output_file} 已经生成"
echo "请将其内容复制到操作系统的 hosts 文件中。"
