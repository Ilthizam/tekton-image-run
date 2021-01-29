#!/usr/bin/env ruby

def create_build_home
  puts "# creating build home #"

  Dir.chdir("/workspace/ifs-applications-repo")
  system("rsync -a */ /workspace/build_home")
end

def download_and_resolve_codegen_artifact
  puts "# downloading and resolving artifacts #"

  source_path = "/workspace/build_home"
  download_path = "/workspace/tmp-artifacts-download-folder"
  destination_path = "/workspace/build_home"
  azure_tenant_id = "afadec18-0533-4cba-8578-5316252ff93f" # TODO: should be env var / configmap
  azure_client_id = "2cfbee7e-7e9c-44a5-889d-0485e72ab26f" # TODO: should be env var / configmap
  azure_client_secret = ENV["AZURE_CLIENT_SECRET"]
  azure_account_name = "ifsartifatctrepository" # TODO: should be env var / configmap
  azure_container = "release" # TODO: should be env var / configmap

  # TODO: remove Dir.mkdir(download_path)

  system("ruby /workspace/scripts/download-manifest-xml-based-artifacts.rb #{source_path} #{download_path} #{destination_path} #{azure_tenant_id} #{azure_client_id} #{azure_client_secret} #{azure_account_name} #{azure_container} \"(fndbas/ifs-code-generator)|(fndbas/installer)|(fndbas/fndbas-binaries)\"")
end

def unzip_codegen_artifact
  puts "# second pass unzip phase (for codegen artifact) #"

  Dir.chdir("/workspace")
  system("unzip -qo build_home/source/fndbas/zip/ifs-code-generator.zip")
end

def run_ant_compile
  puts "# running ant compile #"

  Dir.chdir("/workspace/build_home/build")
  ENV["CLASSPATH"] = "/workspace/ant-contrib/ant-contrib-1.0b3.jar:/workspace/org-netbeans-modules-lexer/org-netbeans-modules-lexer-nbbridge-RELEASE112.jar"

  system("ant -f build.xml -Ddelivery=/workspace/build_home")
end

create_build_home
download_and_resolve_codegen_artifact
unzip_codegen_artifact
run_ant_compile

# system("mkdir -p /workspace/build_home/database") #
