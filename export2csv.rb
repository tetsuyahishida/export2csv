=begin
(c) TIG 2011
Type
  Exportvertices2csv.new
in the Ruby Console.
Exports all Vertices is a Selection to a X,Y,Z 'CSV' file.
Edit sep="," if something other than a separating comma is desired e.g. ';'
Make sep="\t" if a TSV file is desired and change ext="csv" to ext="tsv".
It uses the current Model Units/accuracy with the approximate '~ ' and 
unit suffix [if any] removed; e.g. change Model Units to 'meters' 3dp to 
get exported csv in meters 1.234 - don't use 'fraction' 1' 2 1/2" formats, 
always use a 'decimal' format.
1.0 20110105 First issue.
1.1 20110116 Wrapped in protective class.
=end
=begin
Tetsuya Hishida
2.1 20110416 add icon change name to export2csv
test whether I can over write this
=end
require 'sketchup.rb'
###
class Export2csv
class Geom::Point3d
   def dot(v)
      self.x * v.x + self.y * v.y + self.z * v.z
   end
end
###--------------
def Volume::calculate(fcs)
   volume=0
   for face in fcs
      next unless face.kind_of? Sketchup::Face
      volume += (2*face.area*face.vertices[0].position.to_a.dot(face.normal))/6
      end
   return volume
end
def initialize()
    $KCODE = "u";
    sep="," ### <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ext="csv" ### <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    model=Sketchup.active_model
    ss=model.selection
    fcs=[]
    mat=
    ss.each{|e|fcs << e if e.class==Sketchup::Face }
    puts(fcs)
    if not fcs
      UI.messagebox("No Vertices were Selected.\nExiting.")
    return nil
    end#if
    fcs.flatten!
    fcs2=[("area[m2]")+
    sep+("material")+
    sep+("number of edge")+
    sep+("unit vector_x")+
    sep+("unit vector_y")+
    sep+("unit vector_z")]
    begin
      fcs.each{|v|fcs2 << ((v.area*0.000645*10).round.to_f/10).to_s.gsub(/^~ /,'').to_s+
        sep+v.material.name.gsub(/^~ /,'')+
        sep+v.edges.length.to_s+
        sep+v.normal.x.to_s+
        sep+v.normal.y.to_s+
        sep+v.normal.z.to_s}
    rescue =>ex### trap if open\\
      print(ex)
      UI.messagebox("every face must have it's material")
    end
    volume=Volume.calculate(fcs)#calculate volume
    puts(((volume* 0.000016387*100).round.to_f/100).to_s )
    puts("volume")
    path=model.path

    fcs2.unshift(((volume* 0.000016387064 *1000).round.to_f/1000).to_s)
    fcs2.unshift("volume[m3]")
    
    puts(path)
    puts("＜カレントディレクトリの書き出し＞")
    if not path or path==""
      path=Dir.pwd
      title="Untitled"
    else
      path=File.dirname(path)
      title=model.title
    end#if
    ofile=File.join(path,title+'_faces.'+ext).tr("\\","/")
    begin
      puts(ofile)
      puts("＜ofileの書き出し＞")
      file=File.new(ofile,"w")
    rescue### trap if open\\
      UI.messagebox("facees File:\n\n  "+ofile+"\n\nCannot be written - it's probably already open.\nClose it and try making it again...\n\nExiting...")
    return nil
    end
    
    fcs2.each{|pt|file.puts(pt)}
    fcs2.each{|pt|puts(pt)}
    puts(fcs2.length.to_s)    
    puts("＜面の書き出し＿pt＞")
    file.close
    puts (fcs2.length.to_s)+" faces area output to\n"+ofile
    begin
      UI.openURL("file:/"+ofile)
    rescue
      UI.messagebox("facees File:\n\n  "+ofile+"\n\nは開けませんでした。")
      return nil
    end
end#def
end#class
if( not file_loaded?("Export2csv.rb") )
  UI.menu("Plugins").add_item("export2csv Tool") { Export2csv.new }
  dir = Sketchup.find_support_file("Plugins")
  cmd = UI::Command.new("export2csv Tool") { Export2csv.new }
  cmd.large_icon = cmd.small_icon = dir+"/export2csv.png"
  cmd.status_bar_text = cmd.tooltip = "Tool for exporting selected vertices"
  tb = UI::Toolbar.new("export2csv Tool")
  tb.add_item cmd
  tb.show if tb.get_last_state == -1
  file_loaded("Export2csv.rb")
end


###


