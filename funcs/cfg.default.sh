# -*- coding: utf-8, tab-width: 2 -*-

CFG[bread_hostname]='urdlive'
CFG[bread_chroot_path]='tmp.bread'
CFG[bread_release_codename]='focal'

CFG[cloud_image_tarball]='tmp.cloud_image.tar.xz'
CFG[cloud_image_tar_opt]='--xz'
CFG[ubborg_plan]='tmp.plan'
CFG[playbook]='tmp.playbook.yaml'

CFG[ansible_proxy]="$(ansible_guess_proxy)"



# NB: For "early_file:" options, the initial newline marks verbatim text
#     content. (Verbatim except for that it will be unindented.)
#     Without the initial newline, the value would be interpreted as the
#     path to a local file to be copied.

CFG[early_file:'etc/apt/apt.conf.d/00proxy']='
  # Acquire::http::Proxy "http://apt-cacher-ng.local:3142/";
  '
CFG[early_file:'etc/apt/apt.conf.d/95never-install-recommends']='
  APT::Install-Recommends "0";
  APT::Install-Suggests "0";
  '
CFG[early_file:'etc/apt/apt.conf.d/95no-periodic-interference']='
  APT::Periodic::Enable "0";
  '






return 0
