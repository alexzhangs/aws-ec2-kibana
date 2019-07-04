# aws-ec2-kibana

Install Kibana on AWS EC2 instance.

Tested with Kibana 5.x.

## Get code

```
sudo yum install -y git
git clone https://github.com/alexzhangs/aws-ec2-kibana.git
```

## Install Kibana

Since Kibana 5.x, it requires java 1.8.

First upgrade java version from 1.7 to 1.8 if needs.

```
yum install -y java-1.8.0-openjdk
echo 2 | /usr/sbin/alternatives --config java
java -version
```

Kibana is not avalaible in AWS built-in yum repo, you will need
to provide a repo URL to this script.

I provide a repo URL at
`https://gist.github.com/alexzhangs/d0c858520f79de71543393aa45dccf61/raw`.

elastic.repo

```
[elastic-5.x]
name=Elastic.co repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-kibana
enabled=1
autorefresh=1
type=rpm-md
```

Please note that `gist.github.com` is unaccessable within China deal
to well known reason.

Install Kibana from yum repo:

```
sudo sh aws-ec2-kibana/aws-ec2-kibana-install.sh \
    -r https://gist.github.com/alexzhangs/d0c858520f79de71543393aa45dccf61/raw
```

In case there's other yum repo enabled, you may want to install Kibana
from some repo only, e.g. `elastic-5.x` here, use:

```
sudo sh aws-ec2-kibana/aws-ec2-kibana-install.sh \
    -r https://gist.github.com/alexzhangs/d0c858520f79de71543393aa45dccf61/raw
    -n elastic-5.x
```

Or you can install Kibana from a RPM file path or URL, this is
useful if experiencing slow network during downloading package from yum repo.

from local file:

```
sudo sh aws-ec2-kibana/aws-ec2-kibana-install.sh \
    -f ~/kibana.rpm
```

from URL:

```
sudo sh aws-ec2-kibana/aws-ec2-kibana-install.sh \
    -f http://somewhere.com/kibana.rpm
```

See script help:

```
sh aws-ec2-kibana/aws-ec2-kibana-install.sh -h
```

## Setup Kibana

Run:


```
sudo sh aws-ec2-kibana/aws-ec2-kibana-setup.sh \
    -e <ELASTICSEARCH_URL>
```

If you are running kibana behind nginx, you may need to add this
config:

```
sudo sh aws-ec2-kibana/aws-ec2-kibana-setup.sh \
    -e <ELASTICSEARCH_URL> \
    -s server.basePath="/kibana"
```

And have this in your nginx conf:

```
location /kibana/ {
    proxy_pass http://<ip>:5601/kibana/;
}
```

It's able to specify listen on host, port and other settings
by the script, see script help:

```
sh aws-ec2-kibana/aws-ec2-kibana-setup.sh -h
```
