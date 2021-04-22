use strict;
use warnings;
no strict "refs";

use JSON;

#CONST OF MAP ID
use constant WORLD_ID => 1022;

#GLOBAL VARIABLES
my @games; 
my %actions = (
  "InitGame" => \&init_game,
  "ClientConnect" => \&client_connect,
  "ClientUserinfoChanged" => \&client_user_changed_info,
  "Kill" => \&kill
);
my $current_game = -1;

#LOOP PARSER
while (<>) {
  chomp $_; #CLEANING LINE
  my @line_fields = split(' ', $_);
  my $action = $line_fields[1];
  exec_action($action, @line_fields)

}

#CREATE JSON FILE
my $json_text = JSON->new->encode(\@games);
open(DATA, ">output.json") or die "Could not open file";
print DATA $json_text;  
close (DATA);

#CALL THE FUNCTION IN %actions ACCORDING PARAM ACTION
sub exec_action {
  my ($action, @line) = @_;
  chop $action;
  if (exists($actions{$action})){
    $actions{$action}->(@line);
  }
}

sub init_game {
  my @line = @_;
  $current_game = scalar @games;
  my %new_game = (
    Id => $current_game,
    Total_Kills => 0
  );
  push(@games, \%new_game);
}

#CREATING NEW PLAYER
sub client_connect {
  my @line = @_;
  my $user_id = $line[2];
  my %new_player = (
    Id => $user_id,
    Kills => 0

  );

  if (exists($games[$current_game]{'Players'})){
    my @player_list = @{$games[$current_game]{'Players'}}; #GETTING REFERENCE OF PLAYER LIST INSIDE GAME HASH
    foreach my $player(@player_list) {
      if ($player->{'Id'} == $user_id) {
        return;
      }
    }
  } else {
    $games[$current_game]{'Players'} = (); #CREATING NEW FIELD PLAYER CASE NO PLAYERS REGISTERED
  }

  push( @{$games[$current_game]{'Players'}}, \%new_player); #ADDING THE NEW PLAYER
}

#CHANGING NAME OF PLAYER
sub client_user_changed_info {
  my @line = @_;
  my $user_id = $line[2];
  my $user_info = join(' ', @line[3 .. $#line]); #JOIN CASE BLANK SPACES IN PLAYER NAME
  my @username = $user_info =~ /n\\(.*?)\\t/; #FILTERING STRING WITH REGEX
  
  my @player_list = @{$games[$current_game]{'Players'}};
  foreach my $player (@player_list){
    if ($player->{'Id'} == $user_id) {
      ${$player}{'Nick'} = $username[0];
      last;
    }
  }
    
}

sub kill {
  my $killer_id = $_[2];
  my $killed_id = $_[3];

  if ($killer_id == $killed_id) { return; }

  my @player_list = @{$games[$current_game]{'Players'}};
  if ($killer_id == WORLD_ID) {
    foreach my $player (@player_list) {
      if ($player->{'Id'} == $killed_id) {
        ${$player}{'Kills'} -= 1;
      }
    }
    return;  
  }

  foreach my $player (@player_list){
    if ($player->{'Id'} == $killer_id) {
        ${$player}{'Kills'} += 1;
        $games[$current_game]{'Total_Kills'} += 1;
      }
    }

}