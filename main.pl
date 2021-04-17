use strict;
use warnings;
no strict "refs";

use Data::Dumper;

use constant WORLD_ID => 1022;

my $filename = "games.log";
open(FILE, '<', $filename) or die "Could not open file!";


my @games;
my %actions = (
  "InitGame" => \&init_game,
  "ClientConnect" => \&client_connect,
  "ClientUserinfoChanged" => \&client_user_changed_info,
  "Kill" => \&kill
);
my $current_game = -1;

while (my $line = <FILE>) {
  chomp $line;
  my @line_fields = split(' ', $line);
  my $action = $line_fields[1];
  exec_action($action, @line_fields)

}

open(DATA, ">output.txt") or die "Could not open file"  ;

foreach my $rows (@games) {
  print DATA Dumper $rows;  
}

close (DATA);  

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
    Time => $line[0],
  );
  push(@games, \%new_game);
}

sub client_connect {
  my @line = @_;
  my $user_id = $line[2];
  my %new_player = (
    Id => $user_id,
    Kills => 0

  );

  if (exists($games[$current_game]{'Players'})){
    my @player_list = @{$games[$current_game]{'Players'}};  
    foreach my $player(@player_list) {
      if ($player->{'Id'} == $user_id) {
        return;
      }
    }
  } else {
    $games[$current_game]{'Players'} = ();
  }

  push( @{$games[$current_game]{'Players'}}, \%new_player);
}

sub client_user_changed_info {
  my @line = @_;
  my $user_id = $line[2];
  my $user_info = join(' ', @line[3 .. $#line]);
  my @username = $user_info =~ /n\\(.*?)\\t/;
  
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
      }
    }

}