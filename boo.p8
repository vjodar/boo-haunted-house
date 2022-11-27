pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- boo! haunted house
-- by tHErETROpAUL

function _init()
 
 _upd=update_intro_1
 _drw=draw_intro_1
 
 pcursor={ --player cursor
  x1=1,y1=1, --left/top half
  x2=2,y2=1, --right/top half
  ox1=0,oy1=0, --x1,y1 offset
  ox2=0,oy2=0, --x1,y1 offset
  sprite=206,
  timer=0 --timer for animation
 }
 
 --direction array
	xdir={-1,1,0,0}
	ydir={0,0,-1,1}
  
 --tiles table
 tiles={}
 
 --tiles to be replaced table
 toreplace={}
 
 --tiles to be moved down
 todrop={}
 
 --tiles that need to be tweened
 --down smoothly into place
 fallingtiles={}
 
 --tile sprites/animation frames
 tile_sprites={
  --tombstone
  {136,138,140,142},
  --ghost
  {96,98,100,102,104,106,108,110}, 
  --pumpkin
  {128,130,132,134}, 
  --eyeball
  {160,162,164,166,168,170,172,174},
  --bat
  {192,194,196,198,200,202,204},
  --brain
  {224,226,228,230,232,234,236,238},
 }
 --tile names
 tile_names={
 "tombstone","ghost", 
 "pumpkin","eyeball", 
 "bat","brain"}
 --tile colors
 colors={
  {5,5,1,11,2}, --tombstone
  {7,7,6,6,1}, --ghost
  {3,4,9,9,11}, --pumpkin
  {7,7,8,8,2}, --eyeball
  {8,8,7,1,13}, --bat
  {14,14,2,2,7,13}, --brain
 } 
 --tiles specific explosion sfx
 tile_sounds={
  45, --tombstone
  46, --ghost
  47, --pumpkin
  48, --eyeball
  49, --bat
  50, --brain
 }
 
 --flag for if a move should be
 --undone (i.e. when a move does
 --not result in a match3).
 reverted=false
 
 --flag for if the board has
 --changed since last check; 
 --check again
 boardchanged=true
 
 --hint sqaure to show a valid
 --move when the player is stuck
 hint={
  --draw offscreen until needed
  x=-1,
  y=-1,
  timer=0,
  --table of colors to make hint
  --box slowly flash
  colors={0,1,13,3,11,11,3,13,1,0},
  index=1, --index for colors table
  c=1 --hint box's current color
 }
 
 --pixel table for particle fx
 pixels={}
 
 --screenshake stuff
 camera()
 shake=0
 
 --ui stuff-------------------
 uibat={
  s_t={16,32,48}, --spr table
  i=1, --index
  inc=-1, --incrementer
  s=16, --sprite
  timer=0
 }
 uitomb=222
 
 p_score=0 --player score
 p_goal=100 --player score goal
 p_timer=30 --time limit
 
 uitoptext=(
  "goal:"..p_score..
  "/"..p_goal..
  "time:"..p_timer
 )
 uitoptext_pos=12
 uiendmessage="congratulations! you win!"
 ui_index=1
 showplayagain=false
 
 --frames counter for animations
 frames=0
 
 --intro animation stuff-------
 text1="a"
 text2=""
 text2_c=1
 
 text3="music:"
 text4="\"scarbo - gaspard de la nuit\""
 text5=""
 text6=""
 text7=""
 text8=""
 text9=""
 
 introspr=132
 nametext="jack 'o lantern"
 text_x=36 
 
 --sprites for animation in
 --intro_4
 introsprites={}
 
 add(introsprites,{ --pumpkin
  name="jack",
  s=132,
  s_table={128,130,132,134},
  index=3,
  inc=1,
  x=-16,y=-16,
  deg=0.17
 })
 add(introsprites,{ --tombstone
  name="zombie",
  s=138,
  s_table={136,138,140,142},
  index=2,
  inc=1,
  x=-16,y=-16,
  deg=0.34
 })
 add(introsprites,{ --brain
  name="jar",
  s=232,
  s_table={224,226,228,230,
           232,234,236,238},
  index=5,
  inc=1,
  x=-16,y=-16,
  deg=0.51
 })
 add(introsprites,{ --bat
  name="drac",
  s=198,
  s_table={192,194,196,198,
           200,202,204},
  index=4,
  inc=1,
  x=-16,y=-16,
  deg=0.68
 })
 add(introsprites,{ --eyeball
  name="eye",
  s=166,
  s_table={160,162,164,166,
           168,170,172,174},
  index=4,
  inc=1,
  x=-16,y=-16,
  deg=0.85
 })
 add(introsprites,{ --ghost
  name="boo",
  s=102,
  s_table={96,98,100,102,104,
           106,108,110},
  index=4,
  inc=1,
  x=-16,y=-16,
  deg=1.02
 })
 r=32

 --screen fade in/out stuff---
 fadeperc=0
 shouldfade=false --toggle fade
 fade_inc=-10 --for intro animation
 showskip=false
 
 music(-1)--stop music
 music(0)
end

--tile class
function add_tile(_x,_y)
 --choose rnd tile name/type
 local i=ceil(rnd(#tile_names))
 add(tiles, {
  s=rnd(tile_sprites[i]),--sprite
  name=tile_names[i],--name/type
  x=_x,y=_y, --x,y pos
  ox=0,oy=0, --x,y offsets
  --neighbors/adjascent tiles
  adj_l,adj_r,adj_u,adj_d,
  --set to true when tile should
  --be deleted (ex: in a match3)
  to_del=false,
  timer=0, --timer for animation
  anim_inc=2, --sprite increment
  sound=tile_sounds[i],
  
  update=function(self)
   --update neihbor coordinates
   --first account for edge tiles
   self.adj_l={x=self.x-1,y=self.y}
   self.adj_r={x=self.x+1,y=self.y}
   self.adj_u={x=self.x,y=self.y-1}
   self.adj_d={x=self.x,y=self.y+1}
   
   if self.x==1 then self.adj_l=nil end
   if self.x==6 then self.adj_r=nil end
   if self.y==1 then self.adj_u=nil end
   if self.y==6 then self.adj_d=nil end
      
   --if a tile is not at y=6 and
   --there is an empty space below
   --it, add tile to todrop table
   if self.y<6 and 
     get_tile(self.adj_d.x,
     self.adj_d.y,tiles)==nil
   then
    add(todrop, self)
   end
   
   --tile will be deleted
   if self.to_del then
    --apply explosion effects
	   add_px(self.x,self.y,colors[i])
    p_score+=1
    
    shake+=2 --screenshake
    
    add(toreplace,
     (self.x*10)+self.y
    )
    del(tiles,self)
    sfx(self.sound)  
   end
   
   self.timer+=1
  end,
  
  draw=function(self)
   spr(--draw tile
    self.s,
    self.x*16+self.ox,
    self.y*16+self.oy,
    2,2 --sprites are 16x16
   )
  end
 })
end

--pixel/particle class
function add_px(_x,_y,_col)
	local i,_dx,_dy,_s
	for i=0,40 do
		_dx=rnd(1.5)-0.75
		_dy=rnd(1.5)-0.75
		if i<10 then
		 _s=2 else _s=1
		end
	 add(pixels,{
	  --x,y pos. offset to middle
	  --of a tile sprite
	  x=_x*16+8,y=_y*16+8,
	  
	  size=_s,
	  
	  dx=_dx, --x vel
	  dy=_dy, --y vel
	  
	  --choose a random color from
	  --_c table for the particle
	  c=rnd(_col),
	  lifespan=40-10*(abs(_dx)+abs(_dy)),
	  
	  update=function(self)
	   if self.lifespan<0 then
	    del(pixels,self)
	    return
	   end
	   self.x+=self.dx
	   self.y+=self.dy
	   self.lifespan-=1
	  end,
	  
	  draw=function(self)
	   --draw pixel/particle
	   circfill(
	    self.x,self.y,
	    self.size, self.c)
	  end
	 })
	end
end

--fill board with tiles
function startgame()
 local i,j
 for i=1,6 do
  for j=1,6 do
   --spawn them above screen
   add_tile(i,j-7)
  end
 end
 p_score=0
 p_goal=100
 p_timer=100
 music(-1)--stop music
 music(58)
end
-->8
--updates

function _update60()
 shake_screen()
 animate_hintbox()
 animate_tiles()
 animate_particles()
 animate_cursor()
 animate_ui()
 p_timer-=1/60
 _upd()
end

function update_game()
  
 for t in all(tiles) do
  t:update()
 end
 
 --update ui text
 uitoptext=(
  "goal:"..p_score..
  "/"..p_goal.."        "..
  "time:"..flr(p_timer)
 )
  
 if #todrop>0 then
  _upd=update_tiledrop
  return
 end
 
 if #toreplace>0 then
  --replace all empty spaces
  for coord in all(toreplace) do
   add_tile(
    flr(coord/10),
   --push new tiles above screen
    (coord%10)-7
   )
  end
  _upd=update_tiledrop
  for t in all(tiles) do
   --update tiles so they add
   --themselves to todrop table
   t:update()
  end
  return  
 end
 
 --check for valid moves.
 --if none, end the game
 if boardchanged then
 printh("checking for any valid moves") 
  if anyvalidmoves(tiles)==false 
  and p_score<p_goal
  then
   uiendmessage="no more moves! game over!"
   _upd=update_gameover
   _drw=draw_gameover
   music(-1,2500)
   return
  end
	end
 
 --check for matches if board
 --has changed since last check
 if boardchanged then
	 --check for any match3's
	 check_match3(tiles)
	 boardchanged=false
	end
 
 --move cursor
 move_cursor()
 
 --press 🅾️ to switch cursor
 --orientation
 if btnp(🅾️) then
  change_cursor()
  _upd=update_cursormove
 end
 
 --press ❎ to swap tiles
 if btnp(❎) then
  sfx(40)
  swap_tiles()
  reverted=false
  _upd=update_tileswap
  
  --reset hint box
  hint.timer=0
  hint.index=1
  hint.c=0
  return
 end
 
 if p_timer<0 then
  --prevent negative timer
  uitoptext=(
	  "goal:"..p_score..
	  "/"..p_goal..
	  "        "..
	  "time:0")
	 if tilesto_del(tiles)==0 then
	 --wait for tiles to fall
	  uiendmessage="time's up! game over!"
	  _upd=update_gameover
	  _drw=draw_gameover
	  music(-1,2500)
	  return
	 end
 end
 
 if p_score>=p_goal then
  if tilesto_del(tiles)==0 then
  --wait for tiles to fall
	  _upd=update_gameover
	  _drw=draw_gameover
	  music(-1,2500)
	  return
	 end
 end
 
end

--handles cursor tweening
function update_cursormove()
 if pcursor.ox1>0 then pcursor.ox1-=4 end
 if pcursor.ox1<0 then pcursor.ox1+=4 end
 if pcursor.oy1>0 then pcursor.oy1-=4 end
 if pcursor.oy1<0 then pcursor.oy1+=4 end
 
 if pcursor.ox2>0 then pcursor.ox2-=4 end
 if pcursor.ox2<0 then pcursor.ox2+=4 end
 if pcursor.oy2>0 then pcursor.oy2-=4 end
 if pcursor.oy2<0 then pcursor.oy2+=4 end
 
 if pcursor.ox1==0
 and pcursor.ox2==0
 and pcursor.oy1==0
 and pcursor.oy2==0
 then
	 _upd=update_game
	end
end

--handle tile swap tweening
function update_tileswap()
 t1=get_tile(
  pcursor.x1,pcursor.y1,tiles)
 t2=get_tile(
  pcursor.x2,pcursor.y2,tiles)
 if t1.ox>0 then t1.ox-=4 end
 if t1.ox<0 then t1.ox+=4 end
 if t1.oy>0 then t1.oy-=4 end
 if t1.oy<0 then t1.oy+=4 end
 
 if t2.ox>0 then t2.ox-=4 end
 if t2.ox<0 then t2.ox+=4 end
 if t2.oy>0 then t2.oy-=4 end
 if t2.oy<0 then t2.oy+=4 end
 
 if t1.ox==0 and t1.oy==0
 and t2.ox==0 and t2.oy==0
 then --tween complete
  local tile1=get_tile(pcursor.x1,pcursor.y1,tiles)
  local tile2=get_tile(pcursor.x2,pcursor.y2,tiles)
  --check if move was valid
  if not(validmove(tile1,tiles))
  and not(validmove(tile2,tiles))
  then
   if not(reverted) then 
    --not valid, revert
    sfx(44)
    sfx(40)
    swap_tiles()
    reverted=true --to prevent endless loop
    return
   end
  end
  --valid move, proceed
  _upd=update_game
  --if tiles swapped back due to
  --invalid move, board has not changed.
  if not reverted then
  	boardchanged=true
  end
 end
end

--move down all tiles in todrop
--until they are on bottom row
--or there is another tile below
function update_tiledrop()
 --animate particle effects
 animate_particles()
 
 for t in all(todrop) do
  t.y+=1
  t.oy=-16
  
  --add tile to fallingtiles table
  add(fallingtiles,t)
  
  --remove tile from todrop
  del(todrop,t)
 end
 
 if #fallingtiles>0 then
  _upd=update_tilefall
  return
 end
 
 --tile updates will re-add tile
 --to todrop if there is still
 --space to drop.
 for t in all(tiles) do
  t:update()
 end
 
 --when todrop table is empty,
 --move to update_replace state
 if #todrop==0 then
  rebuild_toreplace()	 
  _upd=update_game
  boardchanged=true
 end
end

--handles tile fall tweening
function update_tilefall()
 --animate particle effects
 animate_particles()
 for t in all(fallingtiles) do
  t.oy+=8
  if t.oy==0 then
   del(fallingtiles,t)
  end
 end
 if #fallingtiles==0 then
  _upd=update_tiledrop
 end
end
-->8
--draws

function _draw()
 pal() --reset palette
 if fadeperc!=0 then
  --fade to black
  fadepal(fadeperc)
 end
 
 _drw()
end

function draw_game()
 cls()
 
 --draw hint box
 rect(
  hint.x*16,hint.y*16,
  hint.x*16+15,hint.y*16+15,
  hint.c
 )
 
 --draw tiles
 for t in all(tiles) do
  t:draw()
 end
 
 draw_cursor()
 
 ui() --user interface
 
 --draw particle effects
 for px in all(pixels) do
  px:draw()
 end

end

function draw_intro_1()
 cls()
 shprint(text1,46,49,9,1)
 shprint(text2,40,58,text2_c,1)
 if showskip then
 	print("SKIP 🅾️/❎",89,122,5)
 end
end

function draw_intro_2()
 cls()
 shprint(text3,50,17,9,1)
 shprint(text4,8,33,9,1)
 shprint(text5,24,41,9,1)
 shprint(text6,30,57,9,1)
 shprint(text7,47,65,9,1)
 shprint(text8,17,81,9,1)
 shprint(text9,24,90,9,1)
 if showskip then
 	print("SKIP 🅾️/❎",89,122,5)
 end
end

function draw_intro_3()
 cls()
 
 spr(introspr,56,41,2,2)
 shprint(nametext,text_x,62,9,1)
 
end

function draw_intro_4()
 cls()
 for spooky in all(introsprites) do
  spr(spooky.s,spooky.x,spooky.y,2,2)
 end
end

function draw_intro_5()
 cls()
 sspr(8,0,42,15,42,40)--boo!
 sspr(45,15,84,12,21,56)--haunted
 sspr(51,1,69,14,31,68)--house!
 
 for spooky in all(introsprites) do
  spr(spooky.s,spooky.x,spooky.y,2,2)
 end
end

function draw_gameover()
 cls()
 
 --draw tiles
 for t in all(tiles) do
  t:draw()
 end
  
 ui() --user interface
 
 --game over message
 if #tiles==0 and #pixels<=800 
 then
 	if uiendmessage=="congratulations! you win!" then
 	 --"happy"
 	 sspr(45,15,24,12,35,42)
 	 sspr(8,15,36,12,59,42)
 	else
 	 --"sad"
 	 sspr(86,2,12,12,47,42)
 	 sspr(57,15,12,12,59,42)
 	 sspr(117,15,12,12,71,42)
 	end
 	--"halloween!"
 	sspr(1,31,115,15,7,56)
 	
 	showplayagain=true
 end
 
 --draw particle effects
 for px in all(pixels) do
  px:draw()
 end
 
end

function ui()
 --top ui bar
 rectfill(9,1,117,8,1)
 rectfill(10,0,118,7,4)
 
 --bottom ui bar
 rectfill(9,120,117,127,1)
 rectfill(10,119,118,126,4)
 
 --corner sprites
 spr(uibat.s,0,0)
 spr(uibat.s,120,0,1,1,true)
 spr(uitomb,0,120)
 spr(uitomb,120,120)
 
  --top text
 shprint(uitoptext,
  uitoptext_pos,1,9,1)
 
 --bottom text
 if showplayagain then
  print( --fill in holes
	  "●/●:play again",
	  12,120,1)
	 shprint(
	  "🅾️/❎:play again",
	  12,120,9,1) 
 else
	 print( --fill in holes
	  "●:rotate    ●:swap tiles",
	  12,120,1)
	 shprint(
	  "🅾️:rotate    ❎:swap tiles",
	  12,120,9,1) 
 end
end

--print text in color c1
--and shadow in color c2
function shprint(_t,_x,_y,_c1,_c2)
 --shadow
 print(_t,_x-1,_y+1,_c2) 
 --main text
 print(_t,_x,_y,_c1) 
end
-->8
--game actions

--move cursor left,right,up,down
function move_cursor()
 local b
 for b=1,4 do
  if btnp(b-1) then
   --save last pos of cursor2
   local lastx1,lasty1,lastx2,lasty2
   lastx1=pcursor.x1
   lasty1=pcursor.y1
   lastx2=pcursor.x2
   lasty2=pcursor.y2
   
   --move cursor
	  pcursor.x1+=xdir[b]
	 	pcursor.y1+=ydir[b]
	 	pcursor.x2+=xdir[b]
	 	pcursor.y2+=ydir[b]
	 	
	 	--restrict cursor to board
	 	pcursor.x1=mid(1,pcursor.x1,6)
	 	pcursor.y1=mid(1,pcursor.y1,6)
	 	pcursor.x2=mid(1,pcursor.x2,6)
	 	pcursor.y2=mid(1,pcursor.y2,6)
	 	
	 	--play sound only if cursor moved
	 	if pcursor.x1!=lastx1 
	 	and pcursor.x2!=lastx2
	 	then
	 	 sfx(43)
	 	end
	 	
	 	--cursors can't intersect
	 	if pcursor.x1==pcursor.x2
	 	and pcursor.y1==pcursor.y2
	 	then
	 	 pcursor.x1=lastx1
	 	 pcursor.y1=lasty1
	 	 pcursor.x2=lastx2
	 	 pcursor.y2=lasty2
	 	end
	 	
	 	--only tween cursor movement
	 	--if cursor actually moved
	 	if lastx1!=pcursorx1 
	 	and lasty1!=pcursor.y1
	 	and lastx2!=pcursorx2 
	 	and lasty2!=pcursor.y2
	 	then
	 	 sfx(43)
		 	pcursor.ox1=-xdir[b]*16
		 	pcursor.oy1=-ydir[b]*16
		 	pcursor.ox2=-xdir[b]*16
		 	pcursor.oy2=-ydir[b]*16
	   _upd=update_cursormove
   end
  end
 end
end

--swap cursor orientation by
--moving cursor2 (x2,y2) only
function change_cursor()
 local c=pcursor
 --set cursor offsets to
 --prev pos for tweening
 c.ox2=c.x2
 c.oy2=c.y2

 if c.y1==c.y2 then
  --when cursor is horizontal,
	 --make it vertical
	 sfx(41)
  c.x2=c.x1
  --can't move beneath board
  if c.y2==6 then c.y2=c.y1-1
  else c.y2=c.y1+1 end
 else
	 --when cursor is vertical,
	 --make it horizontal
	 sfx(42)
  c.y2=c.y1  
  --can't move outside board
  if c.x2==6 then c.x2=c.x1-1
  else c.x2=c.x1+1 end
 end
 
 --update offsets
 if c.x2>c.ox2 then c.ox2=-16 end 
 if c.x2<c.ox2 then c.ox2=16 end
 if c.y2>c.oy2 then c.oy2=-16 end 
 if c.y2<c.oy2 then c.oy2=16 end
end

--get both tiles at the cursors'
--positions, swap their x,y pos
function swap_tiles()
 local t1,t2,tempx,tempy
 --store tile objects
 t1=get_tile(
  pcursor.x1,pcursor.y1,tiles)
 t2=get_tile(
  pcursor.x2,pcursor.y2,tiles)
 --set offsets to prev pos
 t1.ox=t1.x
 t1.oy=t1.y
 t2.ox=t2.x
 t2.oy=t2.y
 --swap x,y pos
 tempx=t1.x
 tempy=t1.y
 t1.x=t2.x
 t1.y=t2.y
 t2.x=tempx
 t2.y=tempy 
 --change offsets to be +/-16
 if t1.x>t1.ox then t1.ox=-16 end
 if t1.x<t1.ox then t1.ox=16 end
 if t1.y>t1.oy then t1.oy=-16 end
 if t1.y<t1.oy then t1.oy=16 end
 
 if t2.x>t2.ox then t2.ox=-16 end
 if t2.x<t2.ox then t2.ox=16 end
 if t2.y>t2.oy then t2.oy=-16 end
 if t2.y<t2.oy then t2.oy=16 end
 
 --if offsets are the same as 
 --new pos, offsets set to 0
 if t1.x==t1.ox then t1.ox=0 end
 if t1.y==t1.oy then t1.oy=0 end
 if t2.x==t2.ox then t2.ox=0 end
 if t2.y==t2.oy then t2.oy=0 end
end
-->8
--tools

--finds a tile object by its
--x,y pos in table _t
--and returns it
function get_tile(_x,_y,_t)
 local i
 for i=1,#_t do
  if _t[i].x==_x
  and _t[i].y==_y then
   return _t[i] 
  end
 end
end

--iterates over table _t, checks
--if current tile is equal in 
--type/name to either 
--adj_l,adj_r or adj_u,adj_d
--if so, add the three tiles
--to a table for deleting
function check_match3(_t)
  local l,r,u,d  
  for t in all(_t) do
  
   --check if an adj tile exists
   --if not store nil, else
   --store tile in l/r/u/d
   if t.adj_l==nil then l=nil
   else 
    l=get_tile( --l
     t.adj_l.x,
     t.adj_l.y,_t
    )
   end
   if t.adj_r==nil then r=nil
   else 
    r=get_tile( --r
     t.adj_r.x,
     t.adj_r.y,_t
    )
   end
   if t.adj_u==nil then u=nil
   else 
    u=get_tile( --u
     t.adj_u.x,
     t.adj_u.y,_t
    )
   end
   if t.adj_d==nil then d=nil
   else 
    d=get_tile( --d
     t.adj_d.x,
     t.adj_d.y,_t
    )
   end
   
   --ensure both l,r exist
   if not(l==nil or r==nil) then
    if t.name==l.name
    and t.name==r.name then
    --t,l,r are a match3, set
    --them all to be removed
     t.to_del=true
     l.to_del=true
     r.to_del=true
    end
   end
   --ensure both u,d exist
   if not(u==nil or d==nil) then
    if t.name==u.name
    and t.name==d.name then
    --t,u,d are a match3, set
    --them all to be removed
     t.to_del=true
     u.to_del=true
     d.to_del=true
    end
   end   
  end
end

--rebuilds the toreplace table
--by starting full, then looping
--through all existing tiles and
--removing their coordinates
function rebuild_toreplace()
 toreplace={}
 local i,j
 for i=1,6 do
  for j=1,6 do
   add(toreplace,(i*10)+j)
  end
 end
 
 for t in all(tiles) do
  del(toreplace,(t.x*10)+t.y)
 end
end

--returns the number of tiles
--that have their to_del property
--set to true
function tilesto_del(_t)
 local res=0
 for t in all(_t) do
  if t.to_del==true then res+=1 end
 end
 return res
end

--returns true if tile _t in
--table _tab is part of a match3
function validmove(_t,_tab)
 local l,ll,r,rr,u,uu,d,dd
 
 --vars for tiles to the left,
 --left of left, right, etc..
 l=get_tile((_t.x-1),(_t.y),_tab)
 ll=get_tile((_t.x-2),(_t.y),_tab)
 r=get_tile((_t.x+1),(_t.y),_tab)
 rr=get_tile((_t.x+2),(_t.y),_tab)
 u=get_tile((_t.x),(_t.y-1),_tab)
 uu=get_tile((_t.x),(_t.y-2),_tab)
 d=get_tile((_t.x),(_t.y+1),_tab)
 dd=get_tile((_t.x),(_t.y+2),_tab)
 
 if l!=nil and r!=nil then
  --check if l and r equal _t
  if _t.name==l.name and
   _t.name==r.name then 
   return true
  end
 end
 
 if u!=nil and d!=nil then
  --check if u and d equal _t
  if _t.name==u.name and
   _t.name==d.name then 
   return true
  end
 end
 
 if l!=nil and ll!=nil then
  --check if l and ll equal _t
  if _t.name==l.name and
   _t.name==ll.name then 
   return true
  end
 end
 
 if r!=nil and rr!=nil then
  --check if r and rr equal _t
  if _t.name==r.name and
   _t.name==rr.name then 
   return true
  end
 end
 
 if u!=nil and uu!=nil then
  --check if u and uu equal _t
  if _t.name==u.name and
   _t.name==uu.name then 
   return true
  end
 end
 
 if d!=nil and dd!=nil then
  --check if d and dd equal _t
  if _t.name==d.name and
   _t.name==dd.name then 
   return true
  end
 end
 
 return false
end

--checks if there are any valid
--moves the player can make by
--generating all child states
--of parent state _t.
function anyvalidmoves(_t)
  
 --iterate through all tiles in
 --parent _t, create children by 
 --applying all moves (swaps) to
 --current tile, check children
 --for valid moves.
 for tile in all(_t) do
  
  --apply each possible move on
  --parent to create a child by
  --swapping with each neighbor
  local i
  for i=1,4 do
  
  --create child by copying only
  --relevant data from parent _t
   local child={}
   for p in all(_t) do
  		add(child,{name=p.name,
  													x=p.x,y=p.y})  													
		 end
		 
		 --get current tile c from
		 --child table
		 local c=get_tile(
		 								tile.x,tile.y,child)
		 
		 --get relevant neighbor tile
		 --and swap with current tile
		 local neighbor
		 neighbor=get_tile(
											  c.x+xdir[i],
											  c.y+ydir[i],
											  child)
		 
		 --swap if neighbor exists
		 if neighbor!=nil then
		  local tempx,tempy
			 tempx=c.x
			 tempy=c.y
			 c.x=neighbor.x
			 c.y=neighbor.y
			 neighbor.x=tempx
			 neighbor.y=tempy
		 end
		 
		 --check if the swap produced
		 --a valid move
		 if validmove(c,child) then		    
		  printh(c.x..","..c.y)
		  printh("")
		  --update hint box
		  hint.x=c.x
		  hint.y=c.y
		  return true
		 end
		 
  end  
 end 
 
 --if all children are generated
 --and none of them had valid
 --moves, return false
 return false
end

--shakes the screen
function shake_screen()
 local shake_x=1-rnd(2)
 local shake_y=1-rnd(2)
 
 camera(shake_x*shake,shake_y*shake)
 
 shake*=0.8
 if shake<0.1 then
  shake=0
 end
end

--fades screen to/from black
function fadepal(_perc) 
 local p=_perc
 
 -- these are helper variables
 local kmax,col,dpal,j,k
 
 -- palette shifiting table.
 -- 15 becomes 14
 -- 14 becomes 13
 -- 13 becomes 1
 -- etc...
 dpal={0,1,1,2,1,13,6,
  4,4,9,3,13,1,13,14}
 
 -- now we go trough all colors
 for j=1,15 do
  --grab the current color
  col = j
  
  --now calculate how many
  --times we want to fade the
  --color.
  kmax=(p+(j*1.46))/22
  
  --now we send the color 
  --through our table kmax
  --times to derive the final
  --color
  for k=1,kmax do
   col=dpal[col]
  end
  
  --finally, we change the
  --palette
  pal(j,col)
 end
end
-->8
--other updates

--game credits
function update_intro_1()
 frames+=1
 if frames==60 then
  text1="a game"
 end
 if frames==120 then
  text1="a game by"
 end
 
 if frames==300 then
  text2="tHErETROpAUL"
 end
 if frames%5==0 then
  text2_c+=1
  if text2_c==15 then
   text2_c=2
  end
 end
  
 if frames==575 then
  --remove text from screen
  text1,text2="",""
 end
 
 if frames==800 then
  frames=0
  _upd=update_intro_2
  _drw=draw_intro_2
  music(-1)--stop music
  music(2)
  return
 end
 
 if (btnp(❎) or btnp(🅾️))
 and showskip then
		frames=0
  fadeperc=100
  _upd=update_intro_5
  _drw=draw_intro_5
  music(-1)--stop music
  music(16)
  return
 end 
 if btnp(❎) or btnp(🅾️) then 
  showskip=true 
 end
end

--music credits
function update_intro_2()
 frames+=1
-- fadeinperc+=1
 if frames==60 then
  text6="\"eyes in the dark\""
 end
 if frames==120 then
  text8="\"spooky scary skeletons\""
 end
 
 if frames==300 then
  text5="cover by tHErETROpAUL"
  text7="by gruber"
  text9=text5
 end
 
 if frames==575 then
  --remove text from screen
  text3,text4,text5,text6="","","",""
  text7,text8,text9="","",""
 end
 
 if frames==800 then
  frames=0
  --start intro3 with black screen
  fadeperc=100
  _upd=update_intro_3
  _drw=draw_intro_3
  music(-1)--stop music
  music(4)
  return
 end
 
 if (btnp(❎) or btnp(🅾️))
 and showskip then
		frames=0
  fadeperc=100
  _upd=update_intro_5
  _drw=draw_intro_5
  music(-1)--stop music
  music(16)
  return
 end 
 if btnp(❎) or btnp(🅾️) then 
  showskip=true 
 end
end

--buildup, character showcase
function update_intro_3()
 frames+=1
 fadeperc+=fade_inc
 fadeperc=mid(0,fadeperc,100)
 
 if frames==1 then
  shake=2
 end
 
 --fadeout pumpkin
 if frames==180 then
  fade_inc=4
 end
 
 --show tombstone
 if frames==315 then
  shake=2
  fade_inc=-15
  introspr=136
	 nametext="zombie gravestone"
	 text_x=32
 end
 
 --fadeout tombstone
 if frames==445 then
  fade_inc=5
 end
 
 --show brain
 if frames==525 then
  shake=2
  fade_inc=-20
  introspr=224
	 nametext="brain in a jar"
	 text_x=37
 end
 
 --fadeout brain
 if frames==615 then
  fade_inc=8
 end
 
 --show bat
 if frames==685 then
  shake=2
  fade_inc=-20
  introspr=198
	 nametext="vampire bat"
	 text_x=44
 end
 
 --fadeout bat
 if frames==745 then
  fade_inc=8
 end
 
 --show eyeball
 if frames==790 then
  shake=2
  fade_inc=-20
  introspr=166
	 nametext="eyeball"
	 text_x=51
 end
 
 --fadeout eyeball
 if frames==835 then
  fade_inc=20
 end
 
 --show ghost
 if frames==840 then
  shake=2
  fade_inc=-20
  introspr=102
	 nametext="ghost"
	 text_x=55
 end
 
 --fadeout ghost
 if frames==865 then
  fade_inc=20
 end
 
 if frames==870 then
  frames=0
  fadeperc=0
  _upd=update_intro_4
  _drw=draw_intro_4
  music(-1)--stop music
  music(15)
  return
 end
 
 if (btnp(❎) or btnp(🅾️))
 and showskip then
		frames=0
  fadeperc=100
  _upd=update_intro_5
  _drw=draw_intro_5
  music(-1)--stop music
  music(16)
  return
 end 
 if btnp(❎) or btnp(🅾️) then 
  showskip=true 
 end
end

--tremello, sprite animations
function update_intro_4()
 frames+=1
 
 animate_introsprites()
 rotate_introsprites()
 
 if frames>175 then
  r+=3
 end
 
 if frames==250 then
  frames=0
  fadeperc=100
  _upd=update_intro_5
  _drw=draw_intro_5
  music(-1)--stop music
  music(16)
  return
 end
 
 if (btnp(❎) or btnp(🅾️))
 and showskip then
		frames=0
  fadeperc=100
  _upd=update_intro_5
  _drw=draw_intro_5
  music(-1)--stop music
  music(16)
  return
 end 
 if btnp(❎) or btnp(🅾️) then 
  showskip=true 
 end
end

--arpeggio, show title screen
function update_intro_5()
 frames+=1
 fadeperc+=fade_inc
 fadeperc=mid(0,fadeperc,100)
 
 --place intro sprites around logo
 introsprites[1].x=23 --pumpkin
 introsprites[1].y=40 
 introsprites[6].x=87 --ghost
 introsprites[6].y=40 
 introsprites[5].x=24 --eyeball
 introsprites[5].y=82
 introsprites[4].x=45 --bat
 introsprites[4].y=83
 introsprites[2].x=65 --tombstone
 introsprites[2].y=82
 introsprites[3].x=86 --brain
 introsprites[3].y=82
 
 animate_introsprites()
 
 if frames==1 then
  shake=16
	 fade_inc=-3
 end
 
 if frames==250 then
  fade_inc=1.5
 end
 
 if frames==320 then
  _upd=update_game
  _drw=draw_game
  fadeperc=0
  frames=0
  startgame()
  return
 end
end

function update_gameover()
 frames+=1
 
 for t in all(tiles) do
  t:update()
 end
 
 --waits until ui text has scrolled
 --to the "you win/lose" message
 --before showing final screen
 if uitoptext!=uiendmessage then
  _upd=update_scrolltextoff
  return
 end
 
 for t in all(tiles) do
  t.to_del=true
 end

 --play endscreen music
 if frames==48 then
  music(-1)
  music(18)
 end
 
 --fadeout
 if btnp(❎) or btnp(🅾️) then
  sfx(43)
  shouldfade=true
 end
 
 --fade to black if shouldfade
 if shouldfade then
  fadeperc+=1
  --restart game once after fade
  if fadeperc==100 then
   _init()
   return
  end
 end
end

--scrolls current uitext out
function update_scrolltextoff()  
 for t in all(tiles) do
  t:update()
 end
 
 if #uitoptext==0 then
  uitoptext_pos=115
  _upd=update_scrolltexton
  return
 end
 
 uitoptext=sub(uitoptext,2)
  
end

--scrolls uiendmessage on 
--to uitoptext
function update_scrolltexton()
 for t in all(tiles) do
  t:update()
 end
 
 --only add letter every three frames
 if frames==3 then
  frames=-1
	 uitoptext=uitoptext..
	  sub(uiendmessage,ui_index,ui_index)
	 ui_index+=1
	end
	frames+=1
 uitoptext_pos-=1

 if uitoptext_pos<13 then
	 ui_index=1
	 _upd=update_gameover
	return
	end
end

-->8
--animations

--animate all particles by
--looping through pixels table,
--calling each update method
function animate_particles()
 for px in all(pixels) do
  px:update()
 end
end

--animates the player cursor
function animate_cursor()
 pcursor.timer+=1
 if pcursor.timer>=30 then
  if pcursor.sprite==206 then
   pcursor.sprite=207
  else pcursor.sprite=206 end
  
  pcursor.timer=0
 end
end

--draws both player cursor sides
--given a single 8*8 sprite
function draw_cursor()  
 local n1,n2,b1,b2,i
 --values for: ul,ur,ll,lr
 n1={0,8,0,8}
 n2={0,0,8,8}
 b1={false,true,false,true}
 b2={false,false,true,true}
 
 for i=1,4 do
  spr(pcursor.sprite,--pcursor1
	  pcursor.x1*16+pcursor.ox1+n1[i],
	  pcursor.y1*16+pcursor.oy1+n2[i],
	  1,1,b1[i],b2[i])
  
  spr(pcursor.sprite,--pcursor2
	  pcursor.x2*16+pcursor.ox2+n1[i],
	  pcursor.y2*16+pcursor.oy2+n2[i],
	  1,1,b1[i],b2[i])
 end
end

--animate tile sprites
function animate_tiles()
 for t in all(tiles) do
 
  if t.name=="tombstone" then
   if t.timer>15 then
    nextframe(tile_sprites[1],t)
    t.timer=0
   end
  end
  
  if t.name=="ghost" then
   if t.timer>10 then
    nextframe(tile_sprites[2],t)
    t.timer=0
   end
  end
  
  if t.name=="pumpkin" then
   if t.timer>5 then
    nextframe(tile_sprites[3],t)
    t.timer=0
   end
  end
  
  if t.name=="eyeball" then
   if t.timer>10 then
    nextframe(tile_sprites[4],t)
    t.timer=0
   end
  end
  
  if t.name=="bat" then
   if t.timer>20 then
    nextframe(tile_sprites[5],t)
    t.timer=0
   end
  end
  
  if t.name=="brain" then
   if t.timer>8 then
    nextframe(tile_sprites[6],t)
    t.timer=0
   end
  end
  
 end
end

--helper function for animate_tiles
--changes a tile's sprite to the
--next frame of animation.
--bounds to the animation table
function nextframe(_sprs,_tile)
 --sprite is on the first frame
 if _tile.s==_sprs[1] then
  _tile.anim_inc=2
 end
 --sprite is on the last frame
 if _tile.s==_sprs[#_sprs] then
  _tile.anim_inc=-2
 end
 --advance to the next frame
 --either left or right
 _tile.s+=_tile.anim_inc
end

--flashes the hintbox surrounding
--a tile involved with a valid
--move when the player gets stuck
function animate_hintbox()
 hint.timer+=1
 
 --four sec since player made a
 --move, show hint
 if hint.timer>8*60 then
  if hint.timer%7==0 then
	  hint.index+=1
	  if hint.index>10 then
	   hint.index=1
	  end
	 end
 end
 hint.c=hint.colors[hint.index]
end

--animates the bats on the ui
function animate_ui()
 uibat.timer+=1
 if uibat.timer==5 then
  if uibat.s==uibat.s_t[1] 
  or uibat.s==uibat.s_t[3]  
  then
   --change looping direction
   uibat.inc=-uibat.inc
  end
  uibat.i+=uibat.inc
  uibat.timer=0
 end
 uibat.s=uibat.s_t[uibat.i]
end

--animate characters on intro
--cinematic and title screen
function animate_introsprites()
 for guy in all(introsprites) do
  
  if guy.name=="jack" then
   if frames%3==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end
  
  if guy.name=="zombie" then
   if frames%8==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end
  
  if guy.name=="jar" then
   if frames%4==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end
  
  if guy.name=="drac" then
   if frames%8==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end
  
  if guy.name=="eye" then
   if frames%4==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end
  
  if guy.name=="boo" then
   if frames%5==0 then
    if guy.s==guy.s_table[1] 
		  or guy.s==guy.s_table[#guy.s_table]  
		  then
		   --change looping direction
		   guy.inc=-guy.inc
		  end
		  guy.index+=guy.inc
   end
   guy.s=guy.s_table[guy.index]
  end  
 end
end

--rotate sprites around center
function rotate_introsprites()
 for guy in all(introsprites) do
  guy.deg-=0.007
  guy.x=55+(r*cos(guy.deg))
  guy.y=55+(r*sin(guy.deg))
 end
end
__gfx__
00000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111111100011111111000111111110011777611000000000000000000000000000000000000000000000000000000000000001111110000000000
00700700d17777776110117777761101177777611d17766661001111101111100111111110011111011111001111111110001111111110011aaa911000000000
00077000d1766666661d1776666661d1776666661d17666661041aa9141aa91011aaaaa91141aa9141aa91011aaaaaa911011aaaaaa91141aa99991000000000
00077000d1666116661d1766666661d1766666661d16666661041a99141a99141aa999999141a99141a99141aa9999999141aa9999999141a999991000000000
00700700d1666016661d1666116661d1666116661d16666661041999141999141a9911999141999141999141a99999999141a999999991419999991000000000
00000000d1666666611d1666016661d1666016661d11666611041999111999141999019991419991419991419991111111419991111111419999991000000000
00000000d1666116661d1666016661d16660166610d1111110041999999999141999019991419991419991419999999991419999999910411999911000000000
00000000d1666016661d1666016661d166601666100d111100041999999999141999019991419991119991419999999991419999999910041111110000000000
10000001d1666666661d1666666661d1666666661001176110041999111999141999019991419999999991411111119991419991111111004111100000000000
11000011d1666666611d1166666611d11666666110d17666100419991419991419999999914199999999914199999999914199999999910011a9110000000000
01181810d1111111110dd111111110dd1111111100d1166110041999141999141199999911411199999111419999999911411999999991041a99910000000000
00111100ddddddddd000dddddddd000dddddddd000dd111100041111141111144111111110444111111100411111111110441111111111041199110000000000
0001100000000000000000000000000000000000000ddddd00044444444444004444444440004444444000444444444400044444444440044111100000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444000000000000
00000000001111111110001111111110011111011111001111101111100111111111001111101111101111101111101111111111100111111111001111111100
00000000011aaaaaa911011aaaaaa91141aa9141aa91041aa9141aa91011aaaaaa91141aa9141aa9141aa9111aa9141aaaaaaaa91011aaaaaa91141aaaaa9110
0000000041aa9999999141aa9999999141a99141a991041a99141a99141aa9999999141a99141a99141a99911a99141a99999999141aa9999999141a99999911
0018180041a99111999141a991119991419991119991041999141999141a99111999141999141999141999991999141999999999141a99999999141999999991
11111111419990019991419990019991419999199991041999111999141999001999141999141999141999999999141111999111141999111111141999119991
00011000419999999991419999999991411999999911041999999999141999999999141999141999141999999999144441999100041999999991041999019991
00000000419999999911419999999911441199999110041999999999141999999999141999111999141999199999100041999100041999999991041999019991
00000000419991111110419991111110044119991100041999111999141999111999141999999999141999119999100041999100041999111111141999019991
00000000419991444400419991444400004419991000041999141999141999141999141999999999141999111999100041999100041999999999141999999991
00181800419991000000419991000000000419991000041999141999141999141999141119999911141999141999100041999100041199999999141999999911
01111110411111000000411111000000000411111000041111141111141111141111144411111110041111141111100041111100044111111111141111111110
11011011444440000000444440000000000444440000044444044444044444044444000444444400044444044444000044444000004444444444044444444400
10000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000000000
0011111011111001111111110011111000001111100000011111111000111100011110001111111110001111111110011111011111011aaa9110000000000000
041aa9141aa91011aaaaaa91141aa91000041aa910000011aaaaa911011a911111aa11011aaaaaa911011aaaaaa91141aa9111aa9141aa999910000000000000
041a99141a99141aa9999999141a991000041a991000041aa999999141a991aa91a99141aa9999999141aa9999999141a99911a99141a9999910000000000000
041999141999141a9911199914199910000419991000041a9911999141a991a991a99141a99999999141a9999999914199999199914199999910000000000000
04199911199914199900199914199910000419991000041999019991419991999199914199911111114199911111114199999999914199999910000000000000
04199999999914199999999914199910000419991000041999019991419991999199914199999999104199999999104199999999914119999110000000000000
04199999999914199999999914199911111419991111141999019991419991999199914199999999104199999999104199919999910411111100000000000000
04199911199914199911199914199999991419999999141999019991419999999999914199911111114199911111114199911999910041111000000000000000
04199914199914199914199914199999991419999999141999999991419999999999914199999999914199999999914199911199910011a91100000000000000
0419991419991419991419991419999999141999999914119999991141119999999111411999999991411999999991419991419991041a999100000000000000
04111114111114111114111114111111111411111111144111111110444111111111004411111111114411111111114111114111110411991100000000000000
04444404444404444404444404444444440444444444004444444440004444444440000444444444400444444444404444404444400441111000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000067777777000000067777777000000000677777770000000006777777700000006777777700000006777777700000
00006777777700000000677777770000000677777777700000677777777700000006777777777000000067777777770000067777777770000067777777770000
00067777777770000006777777777000006777777777770006777777777770000067777777777700000677777777777000677777777777000677777777777000
00677777777777000067777777777700067771777771777067771777771777000677717777717770006777177777177706777177777177706777177777177700
06777777777777700677777777777770067711777711777067711777711777000677117777117770006771177771177706771177771177706771177771177700
06777777777777700677717777717770067711777711777067711777711777000677117777117770006771177771177706771177771177706771177771177700
06771177771177700677117777117770067777777777777067777777777777000677777777777770006777777777777706777777777777706777777777777700
06777777777777700677777777777770067711711777776067777711777116000677117117777760006777771177711606771171177777606777771177711600
06777777777777600677777777777760067771711777777067777711777717000677717117777770006777771177771706777171177777706777771177771700
06771771177717700677177117771770067717777717777067177777777177000677177777177770006717777777717706771777771777706717777777717700
06777177777771700677717777777170066177777761717066717177761777000661777777617170006671717776177706617777776171706671717776177700
06611777776117700661177777611770006776776777110006771176777670000067767767771100000677117677767000677677677711000677117677767000
00677677677767000067767767776700000667767766700000667767766700000006677677667000000066776776670000066776776670000066776776670000
00066776776670000006677677667000000067766000000000067766000000000000677660000000000006776600000000006776600000000006776600000000
00006776600000000000677660000000000006660000000000006660000000000000066600000000000000666000000000000666000000000000666000000000
00000666000000000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000003b000000000000003b00000000000000b300000000000000b300000000000000000000000000000000000000000000000000000000000000000000000
00000b3b3330000000000b3b3330000000000b33b3b0000000000b33b3b000000001111111111000000111111111100000011111111110000001111111111000
0002299b999220000002299b9992200000049b3b3339400000049b3b333940000015555555555100001555555555510000155555555551000015555555555100
002aa294992aa200002aa294992aa2000092299b999229000094999b999949000151115515111550015111551511155001511155151115500151115515111550
02a88a2492a88a2002a88a2492a88a20092aa294992aa29009922994999229900151551515155150015155151515515001515515151551500151551515155150
0922229229222220092222949922222002a88a2492a88a20092aa294992aa2900151115515111150015111551511115001511155151111500151115515111150
02949294992949200994999229994990092222949922229002a88a2492a88a200151551515155550015155151515555001515515151555500151551515155550
0a242a2492a242a00294929499294920099499922999499009222294992222900151551515155550015155151515555001515515151555500151551515155550
0aa2aaa22aaa2aa00a242a2492a242a0029492949929492009949992299949900155553535355550015555353535555001555555555555500155555555555550
0aaaaaaaaaaaaaa00aa2aaa22aaa2aa00a242a2492a242a002949294992949200155553535355550015555353535555001555555555555500155555555555550
0aaaaaaaaaaaaaa00aaaaaaaaaaaaaa00aa2aaa22aaa2aa00a242a2492a242a00155353535355550015535353535555001555555555555500155555555555550
09aaaaaaaaaaaa9009aaaaaaaaaaaa9002aaa2aaaa2aaa2002a2a2a22a2a2a200155333333355550015533333335555001555555555555500155555555555550
009aa2aaaa2aa900009aa2aaaa2aa900002a292aa292a200002a292aa292a2000155553333555510015555333355551001555535353555100155555555555510
0009292aa29290000009292aa2929000000299922999200000029992299920000112223333222110011222333322211001123232323221100112222222222110
00000992299000000000099229900000000009949990000000000994999000000222222222222220022222222222222002222222222222200222222222222220
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000282282000000000028228200000000002822820000000000282282000000000028228200000000002822820000000000282282000000000028228200000
00008887777200000000878777720000000087787772000000008777877200000000877787720000000087777872000000008777778200000000877777780000
00028777778880000002787777888000000277877778800000027778777780000002777877778000000287778777800000028877787780000002788777878000
00877777887778000088777778777800008877777787780000878777777878000087877777787800008778777777880000877787777778000087777877777800
02871178777777200278711787777720027787117877772002777871178777200277787117877720027777871178772002777778711787200277777787117820
0871cc177777778008771cc177777780087771cc177777800877771cc17777800877771cc177778008777771cc177780087777771cc177800877777771cc1780
081c00c1777888200871c00c1777882008871c00c1778820087871c00c177820087871c00c1778200878871c00c1772008788771c00c1720087887781c00c120
021c00c1788777800281c00c1788778002781c00c1787780028781c00c178780028781c00c1787800287781c00c1788002877881c00c1780028778871c00c180
0871cc178777778008771cc178777780087771cc178777800877771cc17877800877771cc178778008777771cc178780087777771cc178800877777771cc1780
08771177777777200877711777777720028777117777772002787771177777200278777117777720027787771177772002778877711777200277788777117720
00878777887772000087787778877200008777877787720000877778777872000087777877787200008877778777820000887777787772000088877778877200
00027887778880000002878777788000000278787778800000027787877780000002778787778000000277887877800000027788878780000002778887788000
00008778877800000000877887780000000088778778000000008877787800000000887778780000000088777788000000008877777800000000887777780000
00000822882000000000082288200000000008228820000000000822882000000000082288200000000008228820000000000822882000000000082288200000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000058008500000000005800850000000000580085000000000058008500000000005800850000000000580085000000000058008500000011110001bb10000
000058800885000000005880088500000000588008850000000058800885000000005880088500000000588008850000000058800885000011bb1000bb110000
00058851158850000005885115885000000588511588500000058851158850000005885115885000000588511588500000058851158850001bb11000b1100000
00588811118885000058881111888500005888111188850000588811118885000058881111888500005888111188850000588811118885001b11000011000000
05588111111885500558811111188550055881111118855005588111111885500558811111188550055881111118855005588111111885501110000000000000
05888d11d118885005888d11d1188850058881d11d188850058881d11d188850058881d11d1888500588811d11d888500588811d11d888500000000000000000
05881d77d111885005881d77d1118850058811d77d118850058811d77d118850058811d77d1188500588111d77d188500588111d77d188500000000000000000
05881777771188500588177777118850058817777771885005881777777188500588177777718850058811777771885005881177777188500000000000000000
058818778711885005881877871188500588178778718850058817877871885005881787787188500588117877818850058811787781885000111100dddddddd
058818778711885005881877871188500588178778718850058817877871885005881787787188500588117877818850058811787781885001555550d0000000
058887777788885005888777778888500588877777788850058887777778885005888777777888500588887777788850058888777778885001151510d0000000
055887000788855005588700078885500558877007788550055887700778855005588770077885500558887000788550055888700078855001515150d0000000
005887000788850000588700078885000058870000788500005887000078850000588700007885000058887000788500005888700078850001555550d0000000
000585000058500000058500005850000005850000585000000585000058500000058500005850000005850000585000000585000058500001553550d0000000
000050000005000000005000000500000000500000050000000050000005000000005000000500000000500000050000000050000005000001223220d0000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222d0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054444500000
00000544445000000000054444500000000005444450000000000544445000000000054444500000000005444450000000000544445000000007777777777000
00077777777770000007777777777000000777777777700000077777777770000007777777777000000777777777700000077777777770000070c2222222e700
0070c000000007000070c000000007000070c000000007000070c000000007000070c000000007000070ce2e0ee007000070c2e000ee0700072c2eee2eeee270
070c0e2e0ee00070070c0e2e0ee00070070c000000000070070c000000000070070c0e2e0ee00070070cee22222e0070070ce2222222e07007ec222222222e70
070cee22222e0070070cee22222e0070070c0ee000ee0070070c0ee000ee0070070cee22222e0070070c22ee2ee22070072c2eee2eeee27007eceeee2eeeee70
070c22ee2ee22070070c22ee2ee22070070ce2222222e070070ce2222222e070070c22ee2ee22070070ce2222222e07007ec222222222e70072c222222222270
070ce2222222e070070ce2222222e070072ceeee2eeee270072ceeee2eeee270070ce2222222e070070ceeee2eeee07007eceeee2eeeee7007ecee2e2ee2ee70
070ceeee2eeee070070ceeee2eeee07007ec222222222e7007ec222222222e70070ceeee2eeee070070c222222222070072c222222222270072c22ee2eee2e70
070c222222222070070c22222222207007eceeee2eeeee7007eceeee2eeeee70070c222222222070070cee2e2e2ee07007ecee2e2ee2ee70070cddddddddd070
070cee2e2e2ee070070cee2e2e2ee070072c222222222270072c222222222270070cee2e2e2ee070070c222e2e22e070072c22ee2eee2e70070c000000000070
070c222e2e22e070070c222e2e22e07007ecee2e2ee2ee7007ecee2e2ee2ee70070c222e2e22e070070cddeeeedd0070070cdddeeeddd070070c000000000070
070cddeeeedd0070070cddeeeedd0070072c22ee2eee2e70072c22ee2eee2e70070cddeeeedd0070070c00dddd000070070c000ddd0000700070c00000000700
0070c0dddd0007000070c0dddd0007000070cdddddddd7000070cdddddddd7000070c0dddd0007000070c000000007000070c000000007000007777777777000
00077777777770000007777777777000000777777777700000077777777770000007777777777000000777777777700000077777777770000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b30000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000
000000000000000000000000000000b33b3b00000001111111110001111111100011111111001177761100000677777770000000000000000000000000000000
000000000000000000000000000049b3b333940000d17777776110117777761101177777611d1776666100006777777777000000000000000000000000000000
00000000000000000000000000092299b999229000d1766666661d1776666661d1776666661d1766666100067777777777700000000000000000000000000000
0000000000000000000000000092aa294992aa2900d1666116661d1766666661d1766666661d1666666100677777777777770000000000000000000000000000
000000000000000000000000002a88a2492a88a200d1666016661d1666116661d1666116661d1666666100677777777777770000000000000000000000000000
000000000000000000000000009222294992222900d1666666611d1666016661d1666016661d1166661100677117777117770000000000000000000000000000
000000000000000000000000009949992299949900d1666116661d1666016661d16660166610d111111000677777777777770000000000000000000000000000
000000000000000000000000002949294992949200d1666016661d1666016661d166601666100d11110000677777777777760000000000000000000000000000
00000000000000000000000000a242a2492a242a00d1666666661d1666666661d166666666100117611000677177117771770000000000000000000000000000
00000000000000000000000000aa2aaa22aaa2aa00d1666666611d1166666611d11666666110d176661000677717777777170000000000000000000000000000
000000000000000000000000002aaa2aaaa2aaa200d1111111110dd111111110dd1111111100d116611000661177777611770000000000000000000000000000
0000000000000000000000000002a292aa292a2000ddddddddd000dddddddd000dddddddd000dd11110000067767767776700000000000000000000000000000
00000000000000000000000000002999229992000000000000000000000000000000000000000ddddd0000006677677667000000000000000000000000000000
00000000000000000000000000000099499900000000000000000000000000000000000000000000000000000677660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000000000000000000000000000000000
00000000000000000000000000011111011111001111111110011111011111011111111111001111111110011111111000000000000000000000000000000000
0000000000000000000000000041aa9141aa91411aaaaaa91141aa9141aa9141aaaaaaaa91411aaaaaa91141aaaaa91100000000000000000000000000000000
0000000000000000000000000041a99141a99141aa9999999141a99141a99141a99999999141aa9999999141a999999110000000000000000000000000000000
0000000000000000000000000041999141999141a99111999141999141999141999999999141a999999991419999999910000000000000000000000000000000
00000000000000000000000000419991119991419990019991419991419991411119991111419991111111419991199910000000000000000000000000000000
00000000000000000000000000419999999991419999999991419991419991444419991000419999999910419990199910000000000000000000000000000000
00000000000000000000000000419999999991419999999991419991119991000419991000419999999910419990199910000000000000000000000000000000
00000000000000000000000000419991119991419991119991419999999991000419991000419991111111419990199910000000000000000000000000000000
00000000000000000000000000419991419991419991419991419999999991000419991000419999999991419999999910000000000000000000000000000000
00000000000000000000000000419991419991419991419991411199999111000419991000411999999991419999999110000000000000000000000000000000
00000000000000000000000000411111411111411111411111444111111100000411111000441111111111411111111100000000000000000000000000000000
00000000000000000000000000444440444440444440444440004444444000000444440000044444444440444444444000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000000000000000000000000
000000000000000000000000000000001111101111100111111110011111011111001111111110001111111110011aaa91100000000000000000000000000000
000000000000000000000000000000041aa9141aa91411aaaaa91141aa9141aa91011aaaaaa911411aaaaaa91141aa9999100000000000000000000000000000
000000000000000000000000000000041a99141a99141aa999999141a99141a99141aa9999999141aa9999999141a99999100000000000000000000000000000
000000000000000000000000000000041999141999141a9911999141999141999141a99999999141a99999999141999999100000000000000000000000000000
00000000000000000000000000000004199911199914199901999141999141999141999111111141999111111141999999100000000000000000000000000000
00000000000000000000000000000004199999999914199901999141999141999141999999999141999999991041199991100000000000000000000000000000
00000000000000000000000000000004199999999914199901999141999111999141999999999141999999991004111111000000000000000000000000000000
00000000000000000000000000000004199911199914199901999141999999999141111111999141999111111100411110000000000000000000000000000000
0000000000000000000000000000000419991419991419999999914199999999914199999999914199999999910011a911000000000000000000000000000000
000000000000000000000000000000041999141999141199999911411199999111419999999911411999999991041a9991000000000000000000000000000000
00000000000000000000000000000004111114111114411111111044411111110041111111111044111111111104119911000000000000000000000000000000
00000000000000000000000000000004444444444400444444444000444444400004444444440004444444444004411110000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000054444500000000000000000000000000000000000
00000000000000000000000000000000028228200000000000058008500000000001111111111000000007777777777000000000000000000000000000000000
00000000000000000000000000000000877877720000000000588008850000000015555555555100000070c00000000700000000000000000000000000000000
0000000000000000000000000000000277877778800000000588511588500000015111551511155000070c000000000070000000000000000000000000000000
0000000000000000000000000000008877777787780000005888111188850000015155151515515000070c0ee000ee0070000000000000000000000000000000
0000000000000000000000000000027787117877772000055881111118855000015111551511115000070ce2222222e070000000000000000000000000000000
0000000000000000000000000000087771cc1777778000058881d11d18885000015155151515555000072ceeee2eeee270000000000000000000000000000000
000000000000000000000000000008871c00c177882000058811d77d1188500001515515151555500007ec222222222e70000000000000000000000000000000
000000000000000000000000000002781c00c17877800005881777777188500001555535353555500007eceeee2eeeee70000000000000000000000000000000
0000000000000000000000000000087771cc1787778000058817877871885000015555353535555000072c222222222270000000000000000000000000000000
000000000000000000000000000002877711777777200005881787787188500001553535353555500007ecee2e2ee2ee70000000000000000000000000000000
0000000000000000000000000000008777877787720000058887777778885000015533333335555000072c22ee2eee2e70000000000000000000000000000000
00000000000000000000000000000002787877788000000558877007788550000155553333555510000070cdddddddd700000000000000000000000000000000
00000000000000000000000000000000887787780000000058870000788500000112223333222110000007777777777000000000000000000000000000000000
00000000000000000000000000000000082288200000000005850000585000000222222222222220000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000df000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011000010017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
911c150007554075500755007550085540855008550085500f5540f5500f5500f5500f5450f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c10a00010f5350f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f5000f50000000000000000000000
912814000e7120e7120e7120e7120e7120e7120e7120e7120e7120e7120e7120e7150e7040e7000e7120e7120e7120e7120e7120e715000000000000000000000000000000000000000000000000000000000000
912814001471214712147121471214712147121471214712147121471214712147150e7040e700147121471214712147121471214715000000000000000000000000000000000000000000000000000000000000
912814001771217712177121771217712177121771217712177121771217712177150e7040e700177121771217712177121771217715000000000000000000000000000000000000000000000000000000000000
912814000272202722027220272202722027220272202722027220272202722027250e7040e700027220272202722027220272202725000000000000000000000000000000000000000000000000000000000000
912814000872208722087220872208722087220872208722087220872208722087250270402700087220872208722087220872208725000000000000000000000000000000000000000000000000000000000000
912814000b7220b7220b7220b7220b7220b7220b7220b7220b7220b7220b7220b72502704027000b7220b7220b7220b7220b7220b725000000000000000000000000000000000000000000000000000000000000
911c0c0007554075500755007550085540855008550085500f5540f5500f5500f5500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91180c0007554075500755007550085540855008550085500f5540f5500f5500f5500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91140c0013554135501355013550145541455014550145501b5541b5501b5501b5500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91100c0013554135501355013550145541455014550145501b5541b5501b5501b5500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910e0c001f5541f5501f5501f55020554205502055020550275542755027550275500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910c0c001f5541f5501f5501f55020554205502055020550275542755027550275500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910a0c002b5542b5502b5502b5502c5542c5502c5502c550335543355033550335500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91080c002b5542b5502b5502b5502c5542c5502c5502c550335543355033550335500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91060c0037554375503755037550385543855038550385503f5543f5503f5503f5500f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91040c0037554375503755037550385543855038550385503f5543f5503f5503f5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
911c0c000255002550025550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
911c0c000455004550045550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91140c000e5500e5500e5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91140c001055010550105550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910e0c001a5501a5501a5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910e0c001c5501c5501c5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910a0c002655026550265550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910a0c003255032550325550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91060c003455034550345550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910a0c002855028550285550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c10c00002c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c524385202c52438525
c10c0000335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e524335203e525
c10c00002b520345202b524345202b520345202b524345202b524345202b520345202b524345202b520345202b520345202b524345202b520345202b524345202b524345202b520345202b524345202b52034525
c1200a000f552105521b5521b552195521755216552145520f5520f5520f552105421654216532005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
c1200a001655216542165321655216542165320f5520f552145521455214552145420f5420f532005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
c1200a001b5521c5522755227552255522355222552205521b5521b5521b5521c5422254222532005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
c10a00000f732167321b7321f73222732277322b7322e7323373237732337322e7322b73227732227321f7321b732167320f732177321c73220732237322873223732207321c7320d732147320d7321c73220732
c10a0000197421d74220742257422974225742207421d7421974214742117420d7520875201752000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1200a000f55210542165421653200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200000000000000000000000000000000000000000000000000
c1200a0014552145420f5420f53200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200000000000000000000000000000000000000000000000000
c1200a001b5521c542225422253200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200000000000000000000000000000000000000000000000000
910600000c6540c645000020000200002000020000200002000020000200002000020000200002000020000200000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000180341a0311c0411d0411f041210412304124041000010000100001000010000100001000010000100001000010000100000000000000000000000000000000000000000000000000000000000000000
010100002403423041210411f0411d0411c0411a04118041000010000100001000010000100001000010000100001000010000100001000010000100001000010000000000000000000000000000000000000000
910400001804018040240402404500002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
490800001016004160001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000
0003000000171171710017115161001711315100171111410017110131001710e1210015100155001010010100101001010010100101001010010100101001010010100001000010000100001000000000000000
d60200003f7700007004670006703f770000700d670006703f7700007015670006703f770000701b650006703f7500007023640006703f740000702b640006403f7200002031610006103f710000103761000610
5e0200003f15000170241503015000070221502e150001701f1502c150000701c1502915000170181502515000070151502015000170111501c150000700c1501710000100001000010000100001000010000100
930100003f07031070360703c0703907024670320703a67015070246701407039670130702467012070376701207026670110603665010050296400d130356300c130296200a12033620081102b6100711031610
c20200003f45021670236703e45225672266723d44226672266723c44226672266723b43225672246723a432236722267238422206721e672374221b67219662176521564213632116220f6120d6120b61209612
920300003f4503f6503f6503f6503f3503e6403e6403e6403e4303e6303d6303d6203d3203d6203d6103d6103c4103c6103c61000600006000060000600006000060000600006000060000600006000060000600
491800002b5622b5652b5622b5652a5622a5652a5622a56523562235652656223562235652356223565235622656226565285622856525562255652a5622a5653b5623b565005020000000000000000000000000
4918000013562135651755217555125521255516552165550b5520b5551755217555025520255517552175551355213555175521755512552125551655216555175521755512552125550b5620b5650050000500
4918000000500005000e5520e55500500005000d5520d55500500005000e5520e55500500005000e5520e55500500005000e5520e55500500005000d5520d5550e5520e5550e5520e55502562025650050000500
491800000050000500135521355500500005001255212555005000050012552125550050000500125521255500500005001355213555005000050012552125551255212555125521255506562065650050000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000010010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000000d8550d8450d8350d8251074510735107251071500615178451783517825178151781510745107350d8550d8450d8350d825107451073510725107150061517845178351782517815178150d8150d825
011d0c20107151984519835198251981510045100351002510015178450f7250f7250f7150f715107151071510715198251982519815198150b0150b0250b7250b0150b7150b71517825178250f7250f7250f715
012000001285512845128351282515745157351572515715006151084510835108251081510815157451573512855128451283512825157451573500c44157251571519845198351982519815198150d8150d825
011d0c20107151e8251e8251e8251e8151502515025150151501517825147251471514715147151571515715157151e8251e8251e8151e81515015150251572515015157151571519825198250f7250f7250f715
0120000019845198350d825018451404014030147221471223825238350b8250b8451504015030157221571219845198350d825018451704019030197221971223825238350b8250b8451c0401e0301e7221e712
012000001e8451e83512825068452104021030217222171228835288252881520040200421e0301e7221e7121e8451e835128250684521040210302572225712288452883528825288151c0301e0201e7121e712
__music__
01 017b4344
04 02030405
00 01424344
04 02060708
00 09131444
00 0a424344
00 0b151644
00 0c424344
00 0d171844
00 0e424344
00 0f191a44
00 10424344
00 111b1b44
00 12424344
04 12424344
04 1d1e1f44
00 20212223
04 25262724
04 33343536
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 3a3b4344
00 3a3b4344
00 3c3d4344
00 3a3e4344
00 3a3e4344
02 3c3f4344

