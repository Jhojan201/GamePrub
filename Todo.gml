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
  
  
  
  
  
  
  
  
  
  
