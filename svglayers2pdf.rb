#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'fileutils'
include FileUtils

# Delete any 
def delete_temporary_files
  rm_f 'temp.svg'
  Dir['slide-*.pdf'].each {|p| rm p }
end

# Clean up any files left over from our last run.
delete_temporary_files
rm_f 'output.pdf'

# Read in our presentation SVG.
doc = open('slides.svg') {|f| Nokogiri::XML(f) }

# Iterate over all the layers in our presentation.
slide_ids = []
doc.xpath('/svg:svg/svg:g[@inkscape:groupmode="layer"]').each do |layer|
  # Collect the IDs of our slides.
  slide_ids << layer['id']

  # Hide layers labelled "hidden" (which contain our tools) and show
  # all other layers.
  if layer['label'] =~ /^hidden: /
    layer['style'] = 'display:none'
  else
    layer['style'] = 'display:inline'
  end
end
slide_ids.reverse!

# Write out the modified SVG file.
File.open('temp.svg', 'w') {|f| f.write(doc.to_xml) }

# Generate a PDF for each slide.
slide_ids.each_with_index do |slide_id, i|
  pdf_name = sprintf("slide-%03d.pdf", i)
  puts "Exporting #{pdf_name}"
  system("inkscape", "--export-pdf=#{pdf_name}", "--export-dpi=300",
         "--export-id=#{slide_id}", "--export-area-page", "temp.svg") or
    raise "Unable to export page"
end

# Combine our PDF files.
slides = Dir["slide-*.pdf"].sort
system(*(["pdftk"] + slides + ["cat", "output", "output.pdf"])) or
    raise "Unable to merge PDFs"

# Clean up our temporary files.
delete_temporary_files
