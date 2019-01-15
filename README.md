# SECURE-SHARE

## Summary

Need to generate a password-protected URL in Apache? Then `secure-share` is for you!

Features:

 * Create password-protected shares in seconds
 * Define your own share name and/or username
 * Randomly generated passwords!
 * Easy to reference individual Apache conf-file-per-share 
 * Automation/unattended friendly

### Dependencies

 * httpd
 * httpd-tools (apachectl, htpasswd)
 * tr

### Supported Systems

`secure-share` has been tested on CentOS Linux 7.

It should work on any modern Linux distribution that meets the above dependencies.

### Installation

1. Clone this repo to your preferred directory (eg: /opt/)

`cd /opt && git clone https://github.com/curtis86/secure-share`

2. Move the sample config and define your config settings in `secure-share.conf`

`mv secure-share.conf-sample secure-share.conf`


### Usage

```
Usage: secure-share <options>

Options:

  -n    Name of share (alphanumeric, dashes, dots and underscores only)
  -u    Specify the username (will be the same as the share name if not specified)
  -p    Specifies the password length
  -f    Do not prompt
  -i    Installs the main Apache conf file
  -h    Displays this help message

  * If no options are specified, a random share will be generated.
```

### Sample output

Create a share called "test_share" with username "testuser" and a random password length of 18 characters:

```
./secure-share -n "test_share" -u "testuser" -p 18

Name: test_share
Username: testuser
Password: ******************

Create share with the above details? <y/n>? y
Share "test_share" created!

Restart Apache <y/n>? y
Apache restarted.
```

## Notes

 * This script assumes that a virtualhost is already configured - `share_parent_path` should point to a directory that exists within this virtualhost's DocumentRoot

 * HTTPS should be used wherever passwords are transmitted! See: [Let's Encrypt](https://letsencrypt.org/)

## TODO

  * Share expiry - auto-expire shares after a certain time limit
  * Custom passwords

### Disclaimer

I'm not a programmer, but I do like to make things! Please use this at your own risk.

#### License

The MIT License (MIT)

Copyright (c) 2019 Curtis K

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
