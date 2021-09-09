///state_machine_init();
///Initilize the variables required for the state engine.
state=noone;
state_next=state;
state_timer=0;
state_map=ds_map_create();
state_keys=ds_map_create(); //The inverse map of the state map.
state_stack=ds_stack_create();
state_new=true;
state_var[0]=0; //Useful for storing variables specific to a specific state.
//Add any new variables you might need for your game here.
state_can_interrupt=true;
//Good examples might be
//state_can_interrupt = false;
//state_is_invincible = false;
//state_direction = -1;

///state_create(Name <string>,Script)
ds_map_replace(state_map,argument[0],argument[1]);
ds_map_replace(state_keys,argument[1],argument[0]);

///state_cleanup()
ds_map_destroy(state_map);
ds_map_destroy(state_keys);
ds_stack_destroy(state_stack);

///state_execute()
if(script_exists(state))
  script_execute(state)
else
  state_switch(ds_map_find_first(state_map));
  
  //////////////////////////////////////////////////
  
  ///state_init(state);
//Sets the default state for the object.  Called only in the create event.
if(is_real(argument[0]))
{
    state=argument[0];
    state_name="Unknown (Use the name to switch next time)";
}
else
{
    state=ds_map_find_value(state_map,argument[0]);
    state_name=argument[0];
}    
state_next=state;
ds_stack_push(state_stack,state);
state_new=true;

  //////////////////////
  
  ///state_switch(state <script or name>,<push to stack?>)
var _push = true;
if(argument_count>1)
  _push=argument[1];
  
  
if(is_real(argument[0]))
{ //you passed a specific script, set it as our next state.
  state_next=argument[0];
}
else
{   //you passed the name of a state, let's try and find it.
  if(ds_map_exists(state_map,argument[0]))
  {
    state_next=ds_map_find_value(state_map,argument[0]);
  }
  else
  {
    show_debug_message("Tried to switch to a non-existent state.  Moving to first state.")
    state_next=ds_map_find_first(state_map);
  }
}
if(_push) 
  ds_stack_push(state_stack,state_next);

  ///state_switch_previous()
ds_stack_pop(state_stack);
var _state=ds_stack_top(state_stack);
state_switch(_state,false);

  
  ///state_update
  if(state_next != state)
{
  state=state_next;
  state_timer=0;
  state_new=true;
}
else
{
  state_timer++;
  state_new=false;
}

  ///state_get_name(<state script>)
//Returns the current state's name or the passed state script's name
if(argument_count>0 && is_real(argument[0]))
{
  if(ds_map_exists(state_keys,argument[0]))
    return(ds_map_find_value(state_keys,argument[0]));
  else
    return("Unknown State Script");
}
else
  return(ds_map_find_value(state_keys,state));
  
  ///////////AQUI TERMINA LA MAQUINA DE ESTADOS QUE EN TEORIA AFECTARAN AL PERSONAJE

//QUIETO
  ///pb_state_stand()
//The Standing State for Platform Boy
if(state_new)
{
    x_speed=0;
    y_speed=0;
    image_speed=0;
    sprite_index=spr_mario_walk;
    image_index=0;
}

if((left_held && !place_meeting_rounded(x-1,y,obj_wall))|| 
   (right_held && !place_meeting_rounded(x+1,y,obj_wall)))
{
    state_switch(pb_state_walk);
}

if(jump_pressed)
{
    state_switch(pb_state_air);
    y_speed-=jump_strength;
}

///Check for no ground.
if(!position_meeting_rounded(x,y+1,obj_ramp) && !place_meeting_rounded(x,y+1,obj_wall))
{
    state_switch(pb_state_air);
}

  ///pb_state_stand()
//The Walking State for Platform Boy
if(state_new)
{
    image_index=1;
    sprite_index=spr_mario_walk;
    stick_to_ground=true;
}

//Adjust Speed
if(right_held||left_held)
{
    var _accel;
    if(run_held)
        _accel=run_accel;
    else
        _accel=walk_accel;
    
    if((x_speed<0 && right_held) || (x_speed>0 && left_held))
        _accel*=slide_factor;
    
    if(!run_held)
        x_speed=approach(x_speed,walk_max*(right_held-left_held),_accel)//x_speed+=(right_held-left_held)*walk_accel;
    else
        x_speed=approach(x_speed,run_max*(right_held-left_held),_accel)//x_speed+=(right_held-left_held)*run_accel;
}
else
    x_speed=approach(x_speed,0,walk_accel);

    

///Check for no speed.
if(x_speed == 0)
{
    state_switch("Stand");
}
else
{   //Update Sprite
    if(right_held)
        image_xscale=1;
    else if(left_held)
        image_xscale=-1;
    
    if((right_held && x_speed>0)) || (left_held && x_speed<0)
    {
        if(!run_held || abs(x_speed)<run_max)
            sprite_index=spr_mario_walk;
        else
            sprite_index=spr_mario_run;
    }
    else if(right_held || left_held)
        sprite_index=spr_mario_slide;
    image_speed=lerp(0,.4,abs(x_speed)/run_max);
}



///Check for no ground.
if(!position_meeting_rounded(x,y+1,obj_ramp) && !place_meeting_rounded(x,y+1,obj_wall))
{
    state_switch("Air");
}

//Horizontal Collision
if(place_meeting_rounded(x+x_speed,y,obj_wall))
{
    x=round(x);
    y=round(y);
    while(!place_meeting_rounded(x+sign(x_speed),y,obj_wall))
    {
        x+=sign(x_speed);
    }
    x_speed=0;
    if(position_meeting_rounded(x,y,obj_ramp))
    {
        while(position_meeting_rounded(x,y,obj_ramp))
        {   //Ramp Up
            y--;
        }
    }
    state_switch("Stand");
}
else
{
    x+=x_speed;
    //Check For Ramps
    if(position_meeting_rounded(x,y,obj_ramp))
    {
        while(position_meeting_rounded(x,y,obj_ramp))
        {   //Ramp Up
            y--;
        }
    }
    else if(stick_to_ground)
    {
        var _check_distance=8;
        for(var i=0;i<_check_distance;i++)
        {
            if(position_meeting_rounded(x,y+i,obj_ramp))
            {
                while(!position_meeting_rounded(x,y+1,obj_ramp))
                    y++;
                    
                if(abs(x_speed)>0)
                    state_switch("Walk");
                else
                    state_switch("Stand");
                break;
            }
        }
        
    }
}

if(jump_pressed)
{ 
    state_switch("Air");
    y_speed-=jump_strength;
}

//ESTO ES LO QUE AFECTA A EL CAMINAR PARADO Y EL RESTO(LO DE ARRIBA)
///pb_state_air()
//The in air State for Platform Boy
if(state_new)
{
    image_speed=0;
    image_index=0;
    state_var[0]=false;
    state_var[1]=false;
    if(air_control_enabled && jump_held && y_speed<0)
    {
        if(abs(x_speed)>=run_max)
            state_var[1]=true;
        state_var[0]=true;   //Keep track of whether I am jumping and if I have let go of jump.
    }
}

//Adjust Y Speeds
if(jump_held && state_var[0] && state_timer < jump_hold_limit)
{
    //show_debug_message("Jump Held");
    y_speed=-jump_strength;
}

if(jump_released)
    state_var[0]=false;

//Apply Gravity
y_speed=min(y_speed+grav,max_grav);


//Basic Vertical Collision Checking
if(place_meeting_rounded(x,y+y_speed,obj_wall) || position_meeting_rounded(x,y+y_speed,obj_ramp))
{   //Snap to floor
    x=round(x);
    y=round(y);
    while(!place_meeting_rounded(x,y+sign(y_speed),obj_wall) && !position_meeting_rounded(x,y+sign(y_speed),obj_ramp))
        y+=sign(y_speed);
    y_speed=0;
    state_var[0]=false;
}
else
{   //Fall
    y+=y_speed;
}

//Change Sprite
if(!state_var[1])
{
    if(y_speed>0)
        sprite_index=spr_mario_fall;
    else
        sprite_index=spr_mario_jump;
}
else
    sprite_index=spr_mario_run_jump;    
    
//Adjust x_speed
if(air_control_enabled && (right_held||left_held))
{
    if(right_held-left_held != 0)
        image_xscale=right_held-left_held;
    if(!run_held)
        x_speed=approach(x_speed,walk_max*(right_held-left_held),walk_accel)//x_speed+=(right_held-left_held)*walk_accel;
    else
        x_speed=approach(x_speed,run_max*(right_held-left_held),run_accel)//x_speed+=(right_held-left_held)*run_accel;
}

    
///check for horizontal collision
if(x_speed != 0)
{
    if(place_meeting_rounded(x+x_speed,y,obj_wall))
    {
        x=round(x);
        y=round(y);
        while(!place_meeting_rounded(x+sign(x_speed),y,obj_wall))
        {
            x+=sign(x_speed);
        }
        x_speed=0;
    }
    else
        x+=x_speed;
}

//Look For State Switches
if((place_meeting_rounded(x,y+1,obj_wall) || position_meeting_rounded(x,y+2,obj_ramp)) && y_speed == 0)
{
    if(x_speed==0)
        state_switch("Stand");
    else
        state_switch("Walk");
}

///MECANICAS EN EL AIREXD


  //////////////////////////////////////////MARIOCAMINASTEP////////////////////////////////////////////////MARIO
  
  ///Properties BOMBILLITA
grav=.25;
max_grav=10;
stick_to_ground=false;

slide_factor=2;

walk_max=2;
walk_accel=.1;
run_max=4;
run_accel=.1;
//Air Control
air_control_enabled=true;
air_x_accel=walk_accel; //How easy is it to move in the air.
jump_strength=5;
jump_hold_limit=15;
//Changing Variables
x_speed=0;
y_speed=0;

//General Helpers
timer=0;

scale=1;
  
  ///Controls
//Directions
up_held=false;
down_held=false;
left_held=false;
right_held=false;

//Mobility
run_held=false;
jump_pressed=false;
jump_held=false;
jump_released=false;

///Setup State Machine for Platform Boy
state_machine_init();

//Define States
state_create("Stand",pb_state_stand);
state_create("Walk",pb_state_walk);
state_create("Air",pb_state_air);
//Set the default state
state_init("Stand");


///////////////////////////////STEP
///Read Controls
//Directions
up_held=keyboard_check(vk_up);
down_held=keyboard_check(vk_down);
left_held=keyboard_check(vk_left);
right_held=keyboard_check(vk_right);

//Mobility
run_held=keyboard_check(vk_shift)
jump_pressed=keyboard_check_pressed(vk_space);
jump_held=keyboard_check(vk_space);
jump_released=keyboard_check_released(vk_space);

//
///Execute Script code.
state_execute();


///ENDSTATE/
///Update State
state_update();















  
