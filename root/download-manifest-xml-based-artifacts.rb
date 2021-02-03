#!/usr/bin/env ruby

# ruby script for downloading and exctracting the ifs code generator TARGET_VERSION setting given a repo

require 'pp'
require 'fileutils'

Thread.abort_on_exception = true

def run_tests
  test_xml = <<END
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <name>mymod</name>
  <artifacts>
    <artifact>
      <id>mymod-binaries</id>
      <description>binary files for mymod component</description>
      <version>1.0.0.1</version>
      <extractpath>\\</extractpath>
      <explode>true</explode>
    </artifact>
    <artifact>
      <id>mymod-artifact-01</id>
      <description>An artifact</description>
      <version>1.0.1.0</version>
      <extractpath>\\source\\mymod\\zip</extractpath>
      <explode>false</explode>
    </artifact>
  </artifacts>
</component>
END

  component_name = extract_component_name_from_manifest(test_xml)
  if component_name != "mymod"
    raise "expected: mymod, actual: " + component_name
  end

  expected_artifacts_section = <<END
    <artifact>
      <id>mymod-binaries</id>
      <description>binary files for mymod component</description>
      <version>1.0.0.1</version>
      <extractpath>\\</extractpath>
      <explode>true</explode>
    </artifact>
    <artifact>
      <id>mymod-artifact-01</id>
      <description>An artifact</description>
      <version>1.0.1.0</version>
      <extractpath>\\source\\mymod\\zip</extractpath>
      <explode>false</explode>
    </artifact>
END

  artifacts_section = extract_artifacts_section_from_manifest_xml(test_xml)
  if artifacts_section != expected_artifacts_section
    puts "expected:"
    pp expected_artifacts_section
    puts "actual:"
    pp artifacts_section
    raise "assertion failed"
  end

  expected_split_artifacts = [
"    <artifact>
      <id>mymod-binaries</id>
      <description>binary files for mymod component</description>
      <version>1.0.0.1</version>
      <extractpath>\\</extractpath>
      <explode>true</explode>
",
"
    <artifact>
      <id>mymod-artifact-01</id>
      <description>An artifact</description>
      <version>1.0.1.0</version>
      <extractpath>\\source\\mymod\\zip</extractpath>
      <explode>false</explode>
"
  ]

  split = split_artifacts(artifacts_section)
  if split != expected_split_artifacts
    puts "expected:"
    p expected_split_artifacts
    puts "actual:"
    p split
    raise "assertion failed"
  end

  expected_artifact_details = {
    id: "mymod-binaries",
    description: "binary files for mymod component",
    version: "1.0.0.1",
    extractpath: "\\",
    explode: true
  }

  details = extract_artifact_details(split[0])

  if details != expected_artifact_details
    puts "expected:"
    p expected_artifact_details
    puts "actual:"
    p details
    raise "assertion failed"
  end

  expected_manifest_artifact_details = [
    {
      id: "mymod-binaries",
      description: "binary files for mymod component",
      version: "1.0.0.1",
      extractpath: "\\",
      explode: true
    },
    {
      id: "mymod-artifact-01",
      description: "An artifact",
      version: "1.0.1.0",
      extractpath: "\\source\\mymod\\zip",
      explode: false
    },
  ]
  details = extract_artifact_details_from_manifest(test_xml)

  if details != expected_manifest_artifact_details
    puts "expected:"
    p expected_manifest_artifact_details
    puts "actual:"
    p details
    raise "assertion failed"
  end

  # puts "tests ok"
end

def extract_artifact_details_from_manifest(xml)
  artifacts_section = extract_artifacts_section_from_manifest_xml(xml)
  split_artifacts(artifacts_section).collect do |str|
    extract_artifact_details(str)
  end
end

def extract_component_name_from_manifest(xml)
  match = extract_sections_from_manifest_xml(xml)
  match[1] if match
end

def extract_artifacts_section_from_manifest_xml(xml)
  match = extract_sections_from_manifest_xml(xml)
  if match
    section = match[2]
    section.split("\n").reject do |line|
      line =~ /^\s*$/
    end.join("\n") + "\n"
  end
end

def split_artifacts(artifacts_section)
  artifacts_section.split(%r{    </artifact>}).select { |str| str =~ /<artifact>/ }
end

def extract_artifact_details(str)
#  match = str.match(
#%r{<artifact>
#\s*<id>(.+)</id>
#\s*<description>(.+)</description>
#\s*<version>(.+)</version>
#\s*<extractpath>(.+)</extractpath>
#\s*<explode>(.+)</explode>}
#  )

  match = str.match(
%r{<artifact>\s*<id>(.+)</id>\s*<description>(.+)</description>\s*<version>(.+)</version>\s*<extractpath>(.+)</extractpath>\s*<explode>(.+)</explode>}
  )


  if match
    {
      id: match[1],
      description: match[2],
      version: match[3],
      extractpath: match[4],
      explode: match[5] == "true",
    }
  end
end

def extract_sections_from_manifest_xml(xml)
#   xml.match(
# %r{<\?xml version="1.0" encoding="UTF-8"\?>
# <component>
#   <name>(\w+)</name>
#   <artifacts>
# ((.|\n)*)
#   </artifacts>
# </component>}
#   )

  xml.match(
%r{<\?xml version="1.0" encoding="UTF-8"\?>\s*<component>\s*<name>(\w+)</name>\s*<artifacts>((.|\n)*)</artifacts>\s*</component>}
  )
end

def get_manifest_files_in_repo(source_path, source_path_type)
  if not File.exist? source_path
    raise "no folder called: #{source_path}"
  end
  glob_pattern = if source_path_type == :build_home_structure
                   File.join(source_path, "build", "artifact", "manifest_*.xml")
                 elsif source_path_type == :component_structure
                   File.join(source_path, "*", "build", "artifact", "manifest_*.xml")
                 else
                   raise "bad source path type: #{source_path_type}"
                 end
  Dir.glob(glob_pattern)
end

def login(azure_tenant_id, azure_client_id, azure_client_secret)
  print "az login... "

  # the tenant is common for whole IFS
  # under tenant are a number of subscriptions
  # az login returns a list of subscriptions
  `az login --service-principal --tenant #{azure_tenant_id} --username #{azure_client_id} --password #{azure_client_secret}`
  if $?.exitstatus != 0
    raise "error during az login"
  end
  puts "ok"
end

def logout
  print "az logout... "
  `az logout`
  if $?.exitstatus != 0
    raise "error during az logout"
  end
  puts "ok"
end

def validate_artifact(azure_account_name, azure_container, component, id, version)
  azure_name = get_azure_name(component, id, version)

  puts "az show #{azure_name}"
  cmd = "az storage blob show --auth-mode login --account-name #{azure_account_name} --container #{azure_container} --name \"#{azure_name}\""
  puts "executing command: #{cmd}"

  result = `#{cmd}`
  if $?.exitstatus != 0
    puts "error during az show #{filename} from #{azure_name}"
  else
    puts result
  end

  puts
  puts
end

def download_artifact_zip(azure_account_name, azure_container, component, id, version, download_path)
  component_download_path = File.join(download_path, component)
  filename = get_azure_filename(id, version)
  destination_path = File.join(component_download_path, filename)
  azure_name = get_azure_name(component, id, version)

  FileUtils.mkdir_p component_download_path

  puts "az download #{azure_name} to #{filename}"
  cmd = "az storage blob download --auth-mode login --account-name #{azure_account_name} --container #{azure_container} --name \"#{azure_name}\" --file \"#{destination_path}\""
  puts "executing command: #{cmd}"

  result = `#{cmd}`
  if $?.exitstatus != 0
    raise "error during az download #{filename} from #{azure_name}"
  else
    puts result
  end

  puts "------------------------------"+id+"------------------------------"

  puts
  puts
end

def get_azure_filename(id, version)
  get_base_filename(id) + "-" + version + ".zip"
end

def get_destination_filename(id)
  get_base_filename(id) + ".zip"
end

def get_base_filename(id)
  if id[0..3] == "ifs-"  
    id
  else  
    "ifs-" + id # TODO: this is weird, look into proper way to name artifact files
  end
end

def get_azure_name(component, id, version)
  path = component + "/" + id + "/" + version
  azure_name = path + "/" + get_azure_filename(id, version)
  azure_name
end

def extract_artifact_metadata_from_repo(source_path, source_path_type)
  manifest_files_in_repo = get_manifest_files_in_repo(source_path.gsub(%r{\\}, "/"), source_path_type)
  manifest_files_in_repo.map do |path|
    manifest = File.read(path)
    puts "---"
    puts "manifest file: " + path
    puts "manifest file content:"
    puts manifest
    puts "---"
    artifacts = extract_artifact_details_from_manifest(manifest)
    artifacts.map do |artifact|
      {
        manifest_path: path,
        component: extract_component_name_from_manifest(manifest),
        description: artifact[:description],
        id: artifact[:id],
        version: artifact[:version],
        extractpath: artifact[:extractpath].gsub(/\\/, "/"),
        explode: artifact[:explode]
      }
    end
  end.flatten
end

def validate_artifacts(artifacts, azure_tenant_id, azure_client_id, azure_client_secret, azure_account_name, azure_container, download_path)
  result = :success

  begin
    artifacts.each do |artifact|
      validate_artifact(azure_account_name, azure_container, artifact[:component], artifact[:id], artifact[:version])
    end
=begin
  rescue StandardError => e
    warn "Error getting artifacts: #{e}"
    result = :error
=end
  end


  result
end

def create_download_path(download_path)
  if File.exists? download_path
    puts "download path \"#{download_path}\" already exists."
  else
    FileUtils.mkdir_p download_path
    puts "download path \"#{download_path}\" created."
  end
end

def download_artifacts(artifacts, azure_tenant_id, azure_client_id, azure_client_secret, azure_account_name, azure_container, download_path)
  result = :success

  threads = []

  artifacts.each do |artifact|
    threads << Thread.new do
      download_artifact_zip(azure_account_name, azure_container, artifact[:component], artifact[:id], artifact[:version], download_path)
    end
  end

  begin
    threads.each{|repo_roots| repo_roots.join}
  rescue StandardError => e
    warn "Error getting artifacts: #{e}"
    result = :error
  end

  result
end

def unzip_file(src, dst)
  cmd = "unzip -o #{src} -d #{dst}" # -d = destination folder, -o overwrite without WITHOUT prompting
  puts "executing command: #{cmd}"
  result = `#{cmd}`
  if $?.exitstatus != 0
    raise "error when unzipping file #{src} to #{dst}"
  end
  puts result
end

def move_and_extract_artifacts(artifacts, download_path, destination_path, destination_path_type)
  if File.exists? destination_path
    puts "extract path \"#{destination_path}\" already exists."
  else
    FileUtils.mkdir_p destination_path
    puts "extract path \"#{destination_path}\" created."
  end

  artifacts.each do |artifact|
    filename = get_azure_filename(artifact[:id], artifact[:version])
    src = File.join(download_path, artifact[:component], filename)
    dst = if destination_path_type == :build_home_structure
            File.join(destination_path, artifact[:extractpath])
          elsif destination_path_type == :component_structure
            File.join(destination_path, artifact[:component], artifact[:extractpath])
          else
            raise "bad destination path type: #{destination_path_type}"
          end
    if File.exists? dst
      puts "file extract path \"#{dst}\" already exists."
    else
      FileUtils.mkdir_p dst
      puts "file extract path \"#{dst}\" created."
    end

    if artifact[:explode]
      puts "unzip #{src} to #{dst}"
      unzip_file(src, dst)
      puts
    else
      puts "copy #{src} to #{File.join(dst, get_destination_filename(artifact[:id]))}"
      FileUtils.copy(src, File.join(dst, get_destination_filename(artifact[:id])))
    end
  end
end

def print_artifacts_details(artifacts)
  puts artifacts.collect { |artifact| get_artifact_details(artifact) }.join("\n")
end

def get_artifact_details(artifact)
  artifact[:component] + " " + artifact[:id] + " (version: " + artifact[:version] + ") - " + artifact[:description]
end

run_tests

if ARGV.size < 8
  puts "arguments are missing!"
  puts "usage:"
  puts "ruby #{File.basename(__FILE__)} <source_path> <download_path> <destination_path> <azure_tenant_id> <azure_client_id> <azure_client_secret> <azure_account_name> <azure_container> [artifacts_to_include_regex]"
  exit
end

source_path = ARGV[0]
download_path = File.expand_path(ARGV[1])
destination_path = File.expand_path(ARGV[2])
azure_tenant_id = ARGV[3]
azure_client_id = ARGV[4]
azure_client_secret = ARGV[5]
azure_account_name = ARGV[6]
azure_container = ARGV[7]
artifacts_to_include_regex = ARGV[8]

validate_only = false

puts "using:"
puts "source_path: " + source_path
puts "download_path: " + download_path
puts "destination_path: " + destination_path
puts "azure_tenant_id: " + azure_tenant_id
puts "azure_client_id: " + azure_client_id
puts "azure_account_name: " + azure_account_name
puts "azure_container: " + azure_container

source_path_type = :build_home_structure
destination_path_type = :build_home_structure

time_started = Time.now

puts "started: #{time_started}"
puts

puts "extracting artifacts from #{source_path}..."
artifacts = extract_artifact_metadata_from_repo(source_path, source_path_type)
puts "extraction ok."
puts
puts "artifacts referred in checkout path (#{source_path}):"
puts
print_artifacts_details(artifacts)
puts
puts "filtering out artifacts"

artifacts_to_include_in_download, artifacts_to_exclude_from_download = artifacts.partition do |artifact|
  if artifacts_to_include_regex
    (artifact[:component]+"/"+artifact[:id]) =~ /#{artifacts_to_include_regex}/
  else
    true
  end
end

puts "artifacts included for download:"
puts
print_artifacts_details(artifacts_to_include_in_download)
puts
puts "artifacts excluded from download:"
puts
print_artifacts_details(artifacts_to_exclude_from_download)

if artifacts_to_include_in_download.empty?
  puts "no artifacts to download, exiting"
  puts
else
  puts "logging into azure..."
  login(azure_tenant_id, azure_client_id, azure_client_secret)
  puts "login ok"

  result = nil

  if validate_only
    puts "validating artifacts..."
    result = validate_artifacts(artifacts_to_include_in_download, azure_tenant_id, azure_client_id, azure_client_secret, azure_account_name, azure_container, download_path)
    if result == :success
      puts "validation ok."
    else
      puts "validation failure, exiting after logout."
    end
  else
    create_download_path(download_path)

    puts "downloading artifacts..."
    result = download_artifacts(artifacts_to_include_in_download, azure_tenant_id, azure_client_id, azure_client_secret, azure_account_name, azure_container, download_path)
    if result == :success
      puts "download ok."
      puts
      puts "moving and extracting artifacts..."
      move_and_extract_artifacts(artifacts_to_include_in_download, download_path, destination_path, destination_path_type)
      puts "move/extraction ok"
    else
      puts "download failure, exiting after logout."
    end
  end

  puts "logging out of azure..."
  logout
  puts "logout ok"

  time_finished = Time.now

  puts "time finished: #{time_finished}"
  puts "run time: #{time_finished - time_started}"
  puts

  exit 1 if result == :error
end
