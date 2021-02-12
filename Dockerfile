FROM ubuntu
USER root


RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests ruby vim rsync curl dos2unix unzip openjdk-14-jdk ant
RUN curl -sL https://github.com/cniweb/ant-contrib/releases/download/v1.0b3/ant-contrib-1.0b3-bin.zip > /tmp/ant-contrib-1.0b3-bin.zip
RUN unzip -qo /tmp/ant-contrib-1.0b3-bin.zip
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash # install azure-cli
RUN mkdir -p /work/org-netbeans-modules-lexer
RUN curl -SL https://repo1.maven.org/maven2/org/netbeans/modules/org-netbeans-modules-lexer-nbbridge/RELEASE112/org-netbeans-modules-lexer-nbbridge-RELEASE112.jar > /work/org-netbeans-modules-lexer/org-netbeans-modules-lexer-nbbridge-RELEASE112.jar


# RUN apk add --no-cache curl
# RUN apk update
WORKDIR /work
# RUN  apk add ruby 

# RUN  apk add vim 
# RUN  apk add rsync 
# RUN  apk add unzip
# RUN apk add sudo
# RUN apk add bash
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash






# ///
COPY ./doit.rb /work/doit.rb
COPY ./download-manifest-xml-based-artifacts.rb /work/download-manifest-xml-based-artifacts.rb

RUN chmod +x /work/doit.rb

RUN dos2unix /work/doit.rb
RUN dos2unix /work/download-manifest-xml-based-artifacts.rb

# CMD ruby start.rb
