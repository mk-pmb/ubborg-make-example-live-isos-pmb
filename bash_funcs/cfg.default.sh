# -*- coding: utf-8, tab-width: 2 -*-

CFG[bread_hostname]='urdlive'
CFG[bread_chroot_path]='tmp.bread'
CFG[bread_release_codename]='focal'
CFG[bread_release_ver_yy]='20'

CFG[cloud_image_url]='https://cloud-images.ubuntu.com/minimal/releases/'$(
  )'<bread_release_codename>/release/ubuntu-<bread_release_ver_yy>.04'$(
  )'-minimal-cloudimg-amd64-root.tar.xz'
CFG[cloud_image_tarball]='tmp.cache/<bread_release_codename>/'
# ^-- Trailing slash = use filename from URL.
CFG[cloud_image_tar_opt]='--xz'

CFG[ubborg_plan]='tmp.plan'
CFG[playbook]='tmp.playbook.yaml'

CFG[iso_output_path]='tmp.livecd.<bread_release_codename>.iso'








return 0
