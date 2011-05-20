=begin
#-----------------------------------------------------------------------------
Copyright 2007, TIG
  Note: 'attribute2csv.calculate' def etc based on (c) AdamB,
  as noted in text below...
#Permission to use, copy, modify, and distribute this software for 
any purpose and without fee is hereby granted, provided this notice 
appears in all copies.
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
Name        : VolumeCalculator
Type        : Tool
Description : A tool to calculate the volume of a selected Groups/Components
Menu Item   : See menu-section at end on including: Plugins -> Volume
Context Menu: Volume
Author      : TetsuyaHishida
Usage       : First select a Group or Component that has faces that form a 
volume, then use the right-click Context-Menu and choose 'Attribute2csv'.
If there is the Plugins Menu Item 'Volume' you can aso pick that.
(see the end menu section on how to activate that option...)
You can make multiple selections and they are processed in turn.

The units will be cu.m

It then calculates the volume enclosed.
A group is made with equivalent faces and a text-tag.
It is named after the volume - e.g. '123.45'
It is put on the current layer buts its contents are layered too.

It shows the volume in the required units using the current 
text/font settings - e.g. '123.45 cu.m'.
A new layer can be made and used.  It is 
named VOLS-nnnnnnnn (where nnnnnnnn is based on the date/time). 
Alternatively you can choose to use any existing layer OR make 
your own 'on the fly' - pick <Make Layer>.  The last used layer 
is the default in that session.
The associated text-tag is put on a separate layer +'-TEXT'.

Before ending it checks if 'Xray Mode' was already switched 'on' at 
the start and if so there is no action and it exits.  Otherwise the 
original selection is 'Hidden' so you can clearly see the volume-group.  
You are then asked in a dialog if you want to leave it 'Hidden'.  
If 'Yes' then it exits leaving it 'Hidden'.  If 'No' the original 
selection is 'Unhidden' and 'Xray Mode' is then switched 'on' so you 
can see the volume-group inside of the original selection and a dialog 
asks if you want to leave 'Xray Mode' switched 'on'.  If you answer 
'No' the normal view is restored and it exits.  If you answer 'Yes' 
it exits leaving 'Xray Mode' switched 'on'.

If you don't want the volume to be visible you can always edit the 
volume's group and either delete all of its geometry, leaving 
the text-tag in place, or just select all geometry and hide it.
Alternatively the Volume Layer and its assocaited '-Text Layer' can 
be switched on/off separately.

'Volume' can't be expected to be 100% foolproof.  E.G. it treats an  
open topped object as if it were solid, and volumes with several  
missing faces or more than two faces sharing an edge will report 
volumes incorrectly too.  Such forms are warned against in a dialog 
and text-tag becomes 'red', BUT they still label.  Keep all shapes  
fully faced for confidence in the results.  Keep the objects' faces  
orientation consistently too - buff=outside - reverse any 'blue' 
ones.  Seeing some reversed faces (shown 'Red')in the final volumes 
also indicates possible inaccuracies in the volume calculated !

With some ingenuity you WILL be able to contrive shapes that fail !

The new 'Volume' groups are given an attribute to identify them.
If you select one you'll get an extra context-menu option:
"Volume >>> CSV", this makes a list of [active] tagged volumes.

Verison:
1.0	17/12/05	First issue.
1.1	18/12/05	Minor adjustments to disc definition and text.
1.2	18/12/05	Circle def moved into Class (Mac friendly).
1.3	19/12/05	Cutting disc made larger to include all bbox.
1.4	20/12/05	V5 only support included.
1.5	21/12/05	Undo text corrected.
1.6	07/01/06	Volume calculation error in non-minZ=0 group fixed.
1.7 14/07/07	Layer, Hide/Show-Edges and Colour Options added.
1.8 11/12/07	Volume Group is now named with its volume, e.g '4.234'
				with NO units.  Volume >>> CSV option added - makes csv 
				file of all 'tagged' volumes.
2.0 12/12/07	Rewritten with AdamB's calculation methods
				Now does multiple group/compo selections in turn.
				Puts volume.text on a separate layer.
2.1	18/12/07	Nested Groups/Components within Groups now 'mined' and each
				calculated.  Dialogs combined into one and only one dialog 
				per selection set.  Reversed faces in some volume-groups now 
				properly colored. Warning at end if any ambiguous forms.
=end
#-----------------------------------------------------------------------------
require 'sketchup.rb'
###------------------
### these next 2 bits are after AdamB (c) defs 12/12/07
class Geom::Point3d
   def dot(v)
      self.x * v.x + self.y * v.y + self.z * v.z
   end
end
###---------------------------------------
class Volume 
###---------------------------------------
def Volume::calculate(entities)
   volume=0
   for face in entities
      next unless face.kind_of? Sketchup::Face
      volume += (2*face.area*face.vertices[0].position.to_a.dot(face.normal))/6
      UI.messagebox("position"+face.vertices[0].position.to_s)
      UI.messagebox("volume"+volume.to_s)
      UI.messagebox("area"+face.area.to_s)
      end
   return volume
   end
### TIG's bits follow...####################--------------------------  
def Volume::run
###
model=Sketchup.active_model
entities=model.entities
model.start_operation("Volume")
view=model.active_view
@oss=model.selection.to_a ### Original Selection Set (OSS)
  if @oss.empty?
    UI.messagebox("NO Selection !")
    return nil
  end#if
ss=[]
@oss.each{|e|
  ss.push(e)if e.typename=="Group" or e.typename=="ComponentInstance"
}
  if not ss
    UI.messagebox("Selection MUST contain a Group or a Component !")
    return nil
  end#if
###
### show VCB and status info
  Sketchup::set_status_text(("Volume Parameters..." ), SB_PROMPT)
  Sketchup::set_status_text(" ", SB_VCB_LABEL)
  Sketchup::set_status_text(" ", SB_VCB_VALUE)
  @slen=ss.length ### v2.1 ###
  return nil if not Volume.dialog ### do dialog...
###
model.selection.clear
### sub-def ###------------------------------------------------
def Volume::process(ss)
 not_perfect=[]
model=Sketchup.active_model
entities=model.active_entities
view=model.active_view
### set colour of volumes
colour=@colour; colour=nil if colour=="<Default>"
###
### process selection set list ###--------------------------
###
ss.each{|sel|### do each group/compo in selection in turn...
### ...
### make vol; get existing container's ents; 'copy' them...
vol=entities.add_group
ventities=vol.entities
###
selected=sel.last
t=selected.transformation
sel=sel-[selected] ### strip off selected
if selected.typename=="Group"
  sentities=selected.entities
  sel.each{|e|t=t*e.transformation} if sel[0]
else
  sentities=selected.definition.entities
  sel.each{|e|t=t*e.transformation} if sel[0]
end#if
faces=[]; sentities.each{|e|faces.push(e)if e.typename=="Face"}
if faces[0] ### fix group glitch
  faces[0].reverse!
  faces[0].reverse!
end#if
nfaces=[]
### add matching faces into new vol group
faces.each{|face|
  ps=[]; face.vertices.each{|v|ps.push(v.position.transform!(t))}
  newf=ventities.add_face(ps)
  nfaces.push(newf)
}
### now get all faces oriented consistently
if nfaces[0]
  nfaces[0].orient_Volume_faces
  continue=true
else
  continue=false ### "empty" container !
end#if
### ###
if continue
 ### ###
 ventities.each{|e|
### show VCB and status info
  Sketchup::set_status_text(("Calculating Volumes..." ), SB_PROMPT)
  Sketchup::set_status_text(" ", SB_VCB_LABEL)
  Sketchup::set_status_text(" ", SB_VCB_VALUE)
  e.material=colour if e.typename=="Face"
  e.back_material="Red" if e.typename=="Face"### so can see if inverted
  e.hidden= true if (e.valid? && e.typename=="Edge") && @hidden=="Yes"
 }#each e
# --------------- get volume ----
volume=Volume.calculate(ventities)### in cubic inches
### check for reversed faces mess up first...
tvol=vol.copy
tentities=tvol.entities
tentities.each{|e|e.reverse! if e.typename=="Face"}
tvolume=Volume.calculate(tentities)
if volume >= tvolume ### OK
  tvol.erase!
else ### probably reversed faces ???
  vol.erase!; vol=tvol; ventities=vol.entities; volume=tvolume
end#if
### check if inside out and flip to fix...
faces=[]; ventities.each{|e|faces.push(e)if e.typename=="Face"}
z=vol.bounds.min.z; fac=faces[0]; zn= -1.0
faces.each{|e|
  if e.bounds.max.z > z and e.normal.z > zn
	zn=e.normal.z; fac=e
  end#if
} ### fac is highest face
flipped=false; flipped=true if fac.normal.z < 0 ### inside out
faces.each{|e|e.reverse!}if flipped
### check for edges with <>2 faces
perfect=true
ventities.each{|e|perfect=false if e.typename=="Edge" and e.faces.length!=2}
not_perfect.push(vol)if not perfect
### convert it to required units...

volumetxt = ((volume* 0.000016387064 *1000).round.to_f/1000).to_s 

###
vol.name=volumetxt ### with NO units
###
layerVolume=@layer
if layerVolume
  layerVolume=model.layers.add(layerVolume)
  layerVolume.page_behavior=(LAYER_IS_HIDDEN_ON_NEW_PAGES | LAYER_HIDDEN_BY_DEFAULT) 
  layerVolume.visible=true
end#if
ventities.each{|e|
  e.layer=layerVolume
}
# add text tag
bb=vol.bounds
xmin=bb.min.x;ymin=bb.min.y;xmax=bb.max.x
ymax=bb.max.y;zmin=bb.min.z;zmax=bb.max.z
apex=Geom.linear_combination(0.5,[xmin,ymin,zmax+2],0.5,[xmax,ymax,zmax+2])
txt=ventities.add_text((volumetxt+" "+@units),apex)
layerVolumeText=@layer+"-TEXT"
if layerVolumeText
  layerVolumeText=model.layers.add(layerVolumeText)
  layerVolumeText.page_behavior=(LAYER_IS_HIDDEN_ON_NEW_PAGES | LAYER_HIDDEN_BY_DEFAULT) 
  layerVolumeText.visible=true
end#if
txt.layer=layerVolumeText
txt.material="Red" if not perfect ### !!!
###
vol.set_attribute("Volume","Tag",true) ### v1.8
### show VCB and status info
  Sketchup::set_status_text((" " ), SB_PROMPT)
  Sketchup::set_status_text(" ", SB_VCB_LABEL)
  Sketchup::set_status_text(" ", SB_VCB_VALUE)
###
 @oss.each{|e|e.hidden=true if @hide=="Yes"}### only hide top level thing(s)
 model.rendering_options["ModelTransparency"]=true if not model.rendering_options["ModelTransparency"] and @hide=="No [BUT X-Ray]"
 #### update view
 view.invalidate
### ###
end#if continue !!!!!!!!!!!!
### ###
}#end each ss
###
model.selection.clear
not_perfect.each{|e|
  e.entities.each{|ee|model.selection.add(ee)if ee.typename!="Text"}
}
s=""; s="s"if not_perfect[1]
UI.messagebox("Volume: WARNING !\n\nAmbiguous Form"+s+" ?\nEach Edge needs exactly TWO Faces !\nOtherwise the Volume"+s+" calculated might be inaccurate.\nEnsure all Faces are made and if you have Edge-to-Edge Forms \nthen sub-Group them to keep confidence in the results.  \n\nSee Selected Volume"+s+" [Red Text]...\n\n")if not_perfect[0]
###
end#def Volume::process
### mine ss for sub-groups and components
def Volume::miner(container_array)
container=container_array.last
if container.typename=="ComponentInstance"
    container.definition.entities.each{|e|
    if e.typename=="Group" or  e.typename=="ComponentInstance"
	  @ss.push(container_array+[e])
	  Volume::miner(container_array+[e])
	end#if
  }#end each
elsif container.typename=="Group"
  container.entities.each{|e|
    if e.typename=="Group" or  e.typename=="ComponentInstance"
	  @ss.push(container_array+[e])
	  Volume::miner(container_array+[e])
	end#if
  }#end each
end#if
end#def
@ss=[]; ss.each{|e|
  @ss.push([e])
} ### a list of base 'containers' each as an array
@ss.each{|part|Volume::miner(part)}
### ### @ss now has all parent and nested groups/compos in it...
Volume::process(@ss) ### run sub-def
### ###
# ---------------------- Close/commit group
model.commit_operation
#-----------------------
end#def
###################################################---------------------
def Volume::dialog
### get units and accuracy etc
   units = ["cu.m", "cc", "cu.yds", "cu.ft", "cu.ins", "litres", "cl", "ml", "gallons(UK)", "gallons(USA)", "quarts(USA)", "pints(UK)", "pints(USA)"].join('|')
   mlayers=Sketchup.active_model.layers
   layers=[]
   mlayers.each{|e|layers.push e.name}
   dlayer=layers[0]
   layers=layers-[dlayer]
   layers.sort!
   #----------- sort possible special Layer
   @sfix=Time::now.to_i.to_s[3..-1]
   layerVolume=("VOLS-"+@sfix)
   @makelayer="<Make New Layer>"
   layers=[layerVolume]+[@makelayer]+[dlayer]+layers
   layers.uniq!
   layers=layers.join('|')
   hidden="Yes|No"
   mcolours=Sketchup.active_model.materials
   colours=[]
   mcolours.each{|e|colours.push e.name}
   colours.sort!
   colours=colours+["<Default>"]+(Sketchup::Color.names.sort!)
   colours.uniq!
   colours=colours.join('|')
   hide="Yes|No|No [BUT X-Ray]"
   prompts = ["Units: ","Layer: ","Hide Edges ? : ","Colour: ","Hide Original: "]
   title = "Volume Parameters: for "+@slen.to_s+" in Selection"
   @units = "cu.m" if not @units
   @layer=layerVolume if not @layer
   @hidden="Yes" if not @hidden
   @colour="<Default>" if not @colour
   @hide="Yes" if not @hide
   values = [@units,@layer,@hidden,@colour,@hide]
   popups = [units,layers,hidden,colours,hide]
   results = inputbox(prompts,values,popups,title)
   return nil if not results
### do processing of results
@units,@layer,@hidden,@colour,@hide=results
### make layer dialog
if @layer==@makelayer
   results2=inputbox(["New Volume's Layer Name: "],["VOLS-????"],"New Layer Name")
   if results2
      @layer=results2[0]
   else
      @layer=nil
   end#if
end#if
###
true
###
end #def dialog
##############-----------------------------------#############
def Volume::list
  model=Sketchup.active_model
  ### check model is saved...
  mname=model.title
  if mname==""
    UI.messagebox("This 'Untitled' new Model must be Saved\nbefore making a Volumes CSV List !\nExiting... ")
    return nil
  end
  mpath=(model.path.split("\\")[0..-2]).join("/")###strip off file name
  entities=model.active_entities
  vols=[]
  entities.each{|e|
    if e.typename=="Group" and e.get_attribute("Volume","Tag",false)
	  vols.push(e.name)
	end#if
  }
  model.start_operation("Volume >>> CSV")
  ###
  Sketchup::set_status_text(("Volume >>> CSV ..." ), SB_PROMPT)
   Sketchup::set_status_text(" ", SB_VCB_LABEL)
   Sketchup::set_status_text(" ", SB_VCB_VALUE)
  vols.sort!
  vcsv=mpath+"/"+mname+"_Volumes.csv"
  begin
    file=File.new(vcsv,"w")
  rescue### trap if open
    UI.messagebox("Volume >>> CSV:\n\n  "+vcsv+"\n\nCannot be written - it's probably already open.\nClose it and try making the List again...\n\nExiting...")
	return nil
  end
  vols.each{|e|
    file.puts(e+"\n")
  }
  file.close
  UI.messagebox("Volume >>> CSV:\n\n  "+vcsv+"\n\nCompleted.")
  ###
  model.commit_operation
end#def
###########################
#-----------------------
end#class
#-----------------------
class Sketchup::Face
 def orient_Volume_faces
    #Sketchup.active_model.start_operation("Orient Faces")
    @face1=self
    @connected_faces=[]
	@face1.all_connected.each{|e|
	  if e.typename=="Face"
		has_neighbor=false
		e.edges.each{|edge|
		  has_neighbor=true if edge.faces[1]
        } ### removes 'connected' BUT not 'co-edged' faces
		@connected_faces.push(e) if has_neighbor
	  end#if
	}
	@awaiting_faces=@connected_faces-[@face1]
	@processed_faces=[]
	face_flip? ### do the first tranche using 'self'
	(@awaiting_faces.length).times do
	  processed_faces=@processed_faces
	  processed_faces.each{|face|
	    Sketchup::set_status_text(("Orient Faces..."),SB_PROMPT)
        Sketchup::set_status_text(" ",SB_VCB_LABEL)
		Sketchup::set_status_text(" ",SB_VCB_VALUE)
		@face1=face; face_flip?
	  }
    end#times
	### now trap for any faces so far missed in processing...
	while @awaiting_faces.length > 0
	  @awaiting_faces.each{|face|
	    face.edges.each{|edge|
          @common_faces=edge.faces
          @common_faces.each{|face2|
            if not @awaiting_faces.include?(face2)
	          @face1=face2; face_flip?
			end#if
		  }
		}
		@waiting_faces=@awaiting_faces-[face]
	  }
	  ### now any faces left must be not 'co-edged' with the main set
	  @awaiting_faces=[]
	end#while
	Sketchup::set_status_text((""),SB_PROMPT)
	#Sketchup.active_model.commit_operation
 end#def
 def face_flip?
    @awaiting_faces=@awaiting_faces-[@face1]
	@processed_faces=[]
    faces=[]
    @face1.edges.each{|edge|
      rev1=edge.reversed_in?(@face1)
      @common_faces=edge.faces-[@face1]
      @common_faces.each{|face2|
	    rev2=edge.reversed_in?(face2)
        face2.reverse! if @awaiting_faces.include?(face2) and rev1==rev2
	    @awaiting_faces=@awaiting_faces-[face2]
	    @processed_faces.push(face2)
	  }
    }
 end#def
end#class
#--------- menu -----------------------------
if( not file_loaded?("attribute2csv.rb") )
   ###add_separator_to_menu("Plugins")
   ###UI.menu("Plugins").add_item("Volume") { Volume.run }
   ###UI.menu("Plugins").add_item("Volume >>> CSV") { Volume.list }
### remove ### in front of above lines if to display in Plugins...
   UI.add_context_menu_handler do | menu |
      if (Sketchup.active_model.selection[0].typename == "Group" or Sketchup.active_model.selection[0].typename == "ComponentInstance")
         menu.add_separator
         menu.add_item("Volume") { Volume.run }
      end #if ok
	  if (Sketchup.active_model.selection[0].get_attribute("Volume","Tag",false))
         menu.add_item("Volumes >>> CSV") { Volume.list }
      end #if ok
   end #do menu
end#if
file_loaded("attribute2csv.rb")
#---------------------------------
