[servers]
{{ range $index, $ip := warren_virtual_machine.warren_test.*.public_ip }}
server{{ $index + 1 }} ansible_host={{ $ip }} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_private_key
{{ end }}
