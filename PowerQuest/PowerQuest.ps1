#PowerQuest - 2021 - Chris Moore

#Choose or create a character
#Create dungeon
#Battles

Set-StrictMode -Version Latest

$classes = [System.Collections.ArrayList]::new()
$chars = [System.Collections.ArrayList]::new()
$classDir = $PSScriptRoot + ".\resources\classes"
$charDir = $PSScriptRoot + ".\saves"
$monsterDir = $PSScriptRoot + ".\resources\monsters"
$roomDir = $PSScriptRoot + ".\resources\rooms"
$shrineDir = $PSScriptRoot + ".\resources\rooms\shrines"
$skillDir = $PSScriptRoot + ".\resources\skills"
$in = ""
$index = 1
$Turn = 1
$Damage = 0
$continue = $false

$Character = [PSCustomObject]@{
    Name = ""
    Class = ""
    Health = 0
    Mana = 0
    Attack = 0
    Defense = 0
    Magic = 0
    Level = 1
    Exp = 0
    NextLevel = 0
    FileName = ""
    Skills = [System.Collections.ArrayList]::new()
}

$CharacterTemp = [PSCustomObject]@{
    Health = 0
    Mana = 0
    Attack = 0
    Defense = 0
    Magic = 0
    Buffs = [System.Collections.ArrayList]::new()
}

$Room = [PSCustomObject]@{
    Monster = $false
    Text = ""
    SkillFamily = ""
    Skills = [System.Collections.ArrayList]::new()
}

$Monster = [PSCustomObject]@{
    Name = ""
    Level = 0
    Health = 0
    Attack = 0
    Defense = 0
    Magic = 0
    Exp = 0
    Skills = [System.Collections.ArrayList]::new()
}

$MonsterTemp = [PSCustomObject]@{
    Health = 0
    Attack = 0
    Defense = 0
    Magic = 0
    Buffs = [System.Collections.ArrayList]::new()
}

function Get-ExpToLevel($Level)
{
    #Experience Curve - (2 * (Level ^ exponent))
    #Calculate the experience needed for the next level
    $Character.NextLevel = [Math]::Round((3 * [Math]::Pow($Level, 1.5)))
}

function Read-Class()
{
    #Reads in class files as txt from the class directory
    foreach ($file in Get-ChildItem $classDir)
    {

        $filePath = $classDir + "\" + $file
        $in = Get-Content -Raw -Path $filePath
        $class = $in | ConvertFrom-Json

        [void]$classes.add($class)
    }
}

function New-Character()
{
    $continue = $false
    Write-Host "`n"
    #Select name, class, and stats
    #Write to file
    Write-Host "Please enter a name"
    while ($continue -eq $false)
    {
        $in = Read-Host
        If ($in -match ".*\d+.*")
        {
            Write-Host "A name may not contain numeric values."
        }
        ElseIf ($in -eq "")
        {
            Write-Host "Name cannot be blank."
        }
        Else 
        {
            $continue = $true 
            $Character.Name = $in
        }
    }
    $continue = $false

    Write-Host "Please choose a class."
    If ($classes.count -eq 0)
    {
        Read-Class
    }

    foreach ($class in $classes)
    {
        Write-Host "$index - " $class.Name
        $index++
    }
    $index -= 1
    while($continue -eq $false)
    {
        $in = Read-Host
        If ($in -le $index -and $in -gt 0)
        {
            $continue = $true
            #Input is valid, copy stats to character
            $index = $in - 1
            $Character.Class = $classes[$index].Name
            $Character.Health = $classes[$index].Health
            $CharacterTemp.Health = $classes[$index].Health
            $Character.Mana = $classes[$index].Mana
            $CharacterTemp.Mana = $classes[$index].Mana
            $Character.Attack = $classes[$index].Attack
            $Character.Defense = $classes[$index].Defense
            $Character.Magic = $classes[$index].Magic
            $Character.Skills.Add("Attack")
            foreach($skill in $classes[$index].Skills)
            {
                $Character.Skills.Add($skill)
            }
            Get-ExpToLevel(2)
        }
        Else
        {
            Write-Host "Invalid input"
        }
    }
}

function Import-Character($Name)
{
    #Loads characters from text files as json objects, then loads them into
    #the character PSObject
    If ($Name -clike '*.txt')
    {
        $charPath = $charDir + "\" + $Name
    }
    Else 
    {
        $charPath = $charDir + "\" + $Name + ".txt"
    }
    $in = Get-Content -Raw -Path $charPath
    $char = $in | ConvertFrom-Json
    [void]$chars.Add($char.Name)
    $Character.Name = $char.Name
    $Character.Class = $char.Class
    $Character.Health = $char.Health
    $CharacterTemp.Health = $char.Health
    $Character.Mana = $char.Mana
    $CharacterTemp.Mana = $char.Mana
    $Character.Attack = $char.Attack
    $Character.Defense = $char.Defense
    $Character.Magic = $char.Magic
    $Character.Level = $char.Level
    $Character.NextLevel = $char.NextLevel
    $Character.Exp = $char.Exp
    $Character.FileName = $char.FileName
    $Character.Skills
    foreach($skill in $char.Skills)
    {
        If (!$Character.Skills.Contains($skill))
        {
            [void]$Character.Skills.Add($skill)
        }
    }
    $Character.Skills
}

function Resume-Game()
{
    #Prints list of characters to load
    $index = 1
    Write-Host "`n"
    foreach ($char in Get-ChildItem $charDir)
    {
        Import-Character -Name $char
        Write-Host "$index -" $Character.Name", Level" $Character.Level $Character.Class
        $index++
    }
    If ($chars.count -gt 0)
    {
        Write-Host "Please choose a character."
    }
    Else
    {
        #There are no characters to load
        Write-Host "There are no characters to load."
        $continue = $true
    }
    $index -= 1
    while ($continue -eq $false)
    {
        $in = Read-Host
        If ($in -le $index -and $in -gt 0)
        {
            $continue = $true
            #Input is valid, load the character
            Import-Character -Name $chars[$in-1]
        }
        Else 
        {
            Write-Host "Invalid input"
        }
    }
}

function Export-Character($Save)
{
    #Saves a character to a text file as json
    #Check if a character with that name already exists
    $index = 0
    If ($Save)
    {
        #Saving over an existing character
        $charPath = $charDir + "\" + $Character.FileName
        $WriteChar = $Character | ConvertTo-Json
        $WriteChar | Out-File -FilePath $charPath
    }
    Else
    {
        #Saving a new character
        foreach ($file in Get-ChildItem $charDir)
        {
            If (($file.Name.TrimEnd(".txt")) -eq $Character.Name)
            {
                $index++
            }
            ElseIf(($file.Name.TrimEnd(".txt")) -eq $Character.Name + $index)
            {
                $index++
            }
        }
        If ($index -gt 0)
        {
            $charPath = $charDir + "\" + $Character.Name + $index + ".txt"
            $Character.FileName = $Character.Name + $index + ".txt"
        }
        Else
        {
            $charPath = $charDir + "\" + $Character.Name + ".txt"
            $Character.FileName = $Character.Name + ".txt"
        }
        $WriteChar = $Character | ConvertTo-Json
        $WriteChar | Out-File -FilePath $charPath
    }
}

function New-Enemy()
{
    #Randomly select an enemy with a level matching the player's
    $monsters = [System.Collections.ArrayList]::new()
    $monsterPath = ""
    $Rand = 0
    foreach ($file in Get-ChildItem -Path ($monsterDir + "\*.txt"))
    {
        $monsterPath = $monsterDir + "\" + $file.Name
        $in = Get-Content -Raw -Path $monsterPath
        $enemy = $in | ConvertFrom-Json
        If($enemy.Level -eq $Character.Level)
        {
            [void]$monsters.Add($file.Name)
        }
    }
    If ($monsters.count -eq 0)
    {
        #There are no monsters of the current level, so randomly select one
        foreach ($file in Get-ChildItem -Path ($monsterDir + "\*.txt"))
        {
            $monsterPath = $monsterDir + "\" + $file.Name
            $in = Get-Content -Raw -Path $monsterPath
            $enemy = $in | ConvertFrom-Json
            [void]$monsters.Add($file.Name)
        }
    }
    If ($monsters.count -eq 0)
    {
        #There are no monsters at all
        Write-Error "There are no monster resources"
    }

    If($monsters.count -eq 1) {$Rand = 0}
    Else
    {
        $Rand = Get-Random -Minimum 0 -Maximum ($monsters.count - 1)
        $monsterPath = $monsterDir + "\" + $monsters[$Rand]
        Write-Host $monsterPath
        $in = Get-Content -Raw -Path $monsterPath
        $enemy = $in | ConvertFrom-Json
    }
    $monsterPath = $monsterDir + "\" + $monsters[$Rand]
    $in = Get-Content -Raw -Path $monsterPath
    $enemy = $in | ConvertFrom-Json
    $Monster.Name = $enemy.Name
    $Monster.Level = $enemy.Level
    $Monster.Health = $enemy.Health
    $MonsterTemp.Health = $enemy.Health
    $Monster.Attack = $enemy.Attack
    $Monster.Defense = $enemy.Defense
    $Monster.Magic = $enemy.Magic
    $Monster.Exp = $enemy.Exp
    $Monster.Skills = $enemy.Skills
}

function Select-Skill()
{
    #Allows the player to select skills from the room's skill list
    $index = 1
    $in = ""
    $choice = ""
    $continue = $false
    Write-Host "`nChoose a skill."
    while ($continue -eq $false)
    {
        $index = 1
        foreach($skill in $Room.Skills)
        {
            Write-Host $index "-" $skill
            $index++
        }
        $in = Read-Host
        If ($in -gt 0 -and $in -le $Room.skills.count)
        {
            $choice = $Room.Skills[$in - 1]
            Write-Host "Choose" $choice"? (y/n)"
            $in = Read-Host
            If ($in -eq 'y')
            {
                [void]$Character.Skills.Add($choice)
                $continue = $true
            }
        }
        #Clear-Host
    }
}

function Set-Skill($Family)
{
    #Using the room's skill family, randomly selects a subset of 3
    #Checks if player already has skills, or if there are not enough skills
    $skills = [System.Collections.ArrayList]::new()
    $skillPath = ""
    $index = 3
    $Rand = 0

    foreach ($file in Get-ChildItem -Path ($skillDir + "\*.txt"))
    {
        $skillPath = $skillDir + "\" + $file.Name
        $in = Get-Content -Raw -Path $skillPath
        $skill= $in | ConvertFrom-Json
        If ($skill.Family -eq $Family)
        {
            [void]$skills.Add($skill.Name)
        }
    }
    while ($index -gt 0 -and $skills.count -gt 0)
    {
        If ($skills.count -eq 1) {$Rand = 0}
        Else {$Rand = Get-Random -Minimum 0 -Maximum ($skills.count - 1)}
        If ($Character.Skills.Contains($skills[$Rand]))
        {
            $skills.RemoveAt($Rand)
        }
        Else
        {
            [void]$Room.Skills.Add($skills[$Rand])
            $skills.RemoveAt($Rand)
        }
        $index--
    }
}

function New-Room()
{
    #Room may have a special feature, and/or monsters
    #Randomly select a room - 20% chance of a shrine
    $rooms = [System.Collections.ArrayList]::new()
    $Room.Skills = [System.Collections.ArrayList]::new()
    $Rand = Get-Random -Minimum 1 -Maximum 100
    $roomPath = ""

    If($Rand -le 100)
    {
        #Generate a shrine room
        foreach ($file in Get-ChildItem -Path ($shrineDir + "\*.txt"))
        {
            [void]$rooms.Add($file.Name)
        }
        If($rooms.count -eq 1) {$Rand = 0}
        Else {$Rand = Get-Random -Minimum 0 -Maximum ($rooms.count - 1)}
        $roomPath = $shrineDir + "\" + $rooms[$Rand]
    }
    ElseIf($Rand -gt 20) 
    {
        #Generate a regular dungeon room
        foreach ($file in Get-ChildItem -Path ($roomDir + "\*.txt"))
        {
            [void]$rooms.Add($file.Name)
        }
        If($rooms.count -eq 1) {$Rand = 0}
        Else {$Rand = Get-Random -Minimum 0 -Maximum ($rooms.count - 1)}
        $roomPath = $roomDir + "\" + $rooms[$Rand]
    }

    $in = Get-Content -Raw -Path $roomPath
    $file = $in | ConvertFrom-Json
    $Room.Text = $file.Text
    $Room.Monster = $file.Monster
    $Room.SkillFamily = $file.SkillFamily
    #Populate the skills array of the room
    If (!$Room.SkillFamily -eq "")
    {
        Set-Skill -Family $Room.SkillFamily
    }
    #Generate an enemy
    If ($Room.Monster -eq $true)
    {
        New-Enemy 
    }
}

function Write-Skill()
{
    #Write the player's list of skills to the screen
    $index = 1
    foreach($skill in $Character.Skills)
    {
        Write-Host $index "-" $skill
        $index++
    }
}

function Write-UI()
{
    #Draw health and mana bars, and print skills to the screen
    #Clear-Host
    $Monster.Name 
    Write-Host "HP:" $MonsterTemp.Health "/" $Monster.Health
    Write-Host "`n====================================`n"
    $Character.Name
    Write-Host "HP:" $CharacterTemp.Health "/" $Character.Health
    Write-Host "MP:" $CharacterTemp.Mana "/" $Character.Mana "`n"
    Write-Skill

    Write-Host "`n(m)enu"
}

function Use-Skill($Name, $User, $TempUser, $Target, $TempTarget)
{
    $skillPath = ""
    $stat = ""
    $Skill = [PSCustomObject]@{
        Name = ""
        Description = ""
        Type = ""
        Family = ""
        Stat = ""
        TargetStat = ""
        FlatDamage = ""
        Multiplier = ""
        Turns = 0
    }
    $buff = [PSCustomObject]@{
        Stat = ""
        Turns = 0
        Value = 0
    }

    #Find a skill file with the given name, import it, and evaluate
    If ($User.Name -eq $Character.Name)
    {
        Write-Host "You use" $Name"!"
    }
    Else
    {
        Write-Host "The"$User.Name "uses" $Name"!"
    }
    foreach($file in Get-ChildItem -Path ($skillDir + "\*.txt"))
    {
        #$skillPath = $skillDir + "\" + $file.Name
        $in = Get-Content -Raw -Path $file
        $skillPath = $in | ConvertFrom-Json
        If ($skillPath.Name -eq $Name)
        {
            #Found the right skill
            $Skill.Name = $skillPath.Name
            $Skill.Description = $skillPath.Description
            $Skill.Type = $skillPath.Type
            $Skill.Family = $skillPath.Family
            $Skill.TargetStat = $skillPath.TargetStat
            $Skill.Stat = $skillPath.Stat
            $Skill.TargetStat = $skillPath.TargetStat
            $Skill.FlatDamage = $skillPath.FlatDamage
            $Skill.Multiplier = $skillPath.Multiplier
            $Skill.Turns = $skillPath.Turns
            break
        }
    }
    If (!$Skill.Name -eq $Name)
    {
        #Still haven't found the skill
        Write-Error "Skill $Name not found"
    }

    #Now that the skill is loaded, we can use it
    switch ($Skill.Stat)
    {
        Health
        {
            $stat = $User.Health
        }
        Mana
        {
            $stat = $User.Mana
        }
        Attack
        {
            $stat = $User.Attack
        }
        Defense
        {
            $stat = $User.Defense
        }
        Magic
        {
            $stat = $User.Magic
        }
        default
        {
            $stat = 0
        }
    }
    $Damage = $Skill.FlatDamage + ($stat * $Skill.Multiplier)
    If ($Skill.Type -eq "Buff" -or $Skill.Type -eq "Heal")
    {
        #The skill will increase one of the user's stats
        #If the skill has a turn count greater than 0,
        #and targets a stat other than health or mana, 
        #create a buff entry
        switch ($Skill.TargetStat)
        {
            Health
            {
                $TempUser.Health += $Damage
                If ($TempUser.Health -gt $User.Health) {$TempUser.Health = $User.Health}
            }
            Mana
            {
                $TempUser.Mana += $Damage
            }
            Attack
            {
                $TempUser.Attack += $Damage
                $buff.Stat = "Attack"
                $buff.Turns = $Skill.Turns
                $buff.Value = $Damage
            }
            Defense
            {
                $TempUser.Defense += $Damage
                $buff.Stat = "Defense"
                $buff.Turns = $Skill.Turns
                $buff.Value = $Damage
            }
            Magic
            {
                $TempUser.Defense += $Damage
                $buff.Stat = "Magic"
                $buff.Turns = $Skill.Turns
                $buff.Value = $Damage
            }
        }
    }
    Else
    {
        #The skill will target one of the enemy's stats
        #If the skill has a turn count greater than 0,
        #and targets a stat other than health or mana, 
        #create a (de)buff entry
        $Damage -= ($Target.Defense + $TempTarget.Defense)
        switch ($Skill.TargetStat)
        {
            Health
            {
                $TempTarget.Health -= $Damage
                If ($TempTarget.Health -lt 0) {$TempTarget.Health = 0}
            }
            Attack
            {
                $TempTarget.Attack -= $Damage
                $buff.Stat = "Attack"
                $buff.Turns = $Skill.Turns
                $buff.Value = -$Damage
            }
            Defense
            {
                $TempTarget.Defense -= $Damage
                $buff.Stat = "Defense"
                $buff.Turns = $Skill.Turns
                $buff.Value = -$Damage
            }
            Magic
            {
                $TempTarget.Magic -= $Damage
                $buff.Stat = "Magic"
                $buff.Turns = $Skill.Turns
                $buff.Value = -$Damage
            }
        }
    }
    If ($Skill.Turns -eq 0)
    {
        If ($Skill.TargetStat -eq "Health" -or $Skill.TargetStat -eq "Mana")
        {
            Write-Host "It deals" $Damage "damage!"
        }
        Else
        {
            Write-Host $Skill.TargetStat "is reduced by" $Damage"!"
        }
    }
    Else
    {
        Write-Host $Skill.TargetStat "will be reduced by" $Damage "for" $Skill.Turns "turns!"
    }
    Read-Host
}

function Get-MonsterSkill($Turn)
{
    #Use the turn counter to choose a skill for the monster to use
    $skillName = $Monster.Skills[$Turn % $Monster.Skills.count]
    Use-Skill -Name $skillName -User $Monster -TempUser $MonsterTemp -Target $Character -TempTarget $CharacterTemp
}

function Grant-Level()
{
    #Increase the character's level by 1
    $Character.Level++
    Get-ExpToLevel -Level ($Character.Level + 1)
    Write-Host "You leveled up to" $Character.Level"!"
}

function Step-Buffs()
{
    #Evaluates any buffs or debuffs currently active on a target
    
}

function Start-Battle()
{
    #Print UI elements and player skills onto the screen
    $continue = $false
    $Turn = 0

    while ($CharacterTemp.Health -gt 0)
    {
        $continue = $false
        Write-UI
        while ($continue -eq $false)
        {
            $in = Read-Host
            If ($in -gt 0 -and $in -le $Character.Skills.count)
            {
                Use-Skill -Name $Character.Skills[$in-1] -User $Character -TempUser $CharacterTemp -Target $Monster -TempTarget $MonsterTemp
                If ($MonsterTemp.Health -gt 0)
                {
                    Get-MonsterSkill -Turn $Turn
                }
                $continue = $true
                $Turn++
            }
            ElseIf ($in -eq 'm')
            {  
                #Display menu
                continue
            }
            Else
            {
                Write-Host "Invalid input"
            }
        }
        If ($MonsterTemp.Health -eq 0)
        {
            #You won!
            Clear-Host
            Write-Host "You defeated the" $Monster.Name"!`n"
            Write-Host "You gained" $Monster.Exp "experience points!"
            $Character.Exp += $Monster.Exp
            Write-Host $Character.Exp / $Character.NextLevel
            #Check for level-up
            If ($Character.Exp -ge $Character.NextLevel)
            {
                Grant-Level
                #Refill character health
                $CharacterTemp.Health = $Character.Health
            }
            #Save the character
            Export-Character -Save $true
            Read-Host
            break
        }
    }
}

#Main

Write-Host "`nWelcome to PowerQuest!"
Write-Host "Create a new character or choose an existing one.`n"

Write-Host "1 - [n]ew Character"
Write-Host "2 - [c]ontinue"

while ($continue -eq $false)
{
    $in = Read-Host
    If ($in -eq 1 -or $in -eq 'n')
    {
        #Create Character
        New-Character
        while ($continue -eq $false)
        {
            Write-Host "`n"
            Write-Host "Name:       " $Character.Name
            Write-Host "Class:      " $Character.Class
            Write-Host "Health:     " $Character.Health
            Write-Host "Mana:       " $Character.Mana
            Write-Host "Attack:     " $Character.Attack
            Write-Host "Defense:    " $Character.Defense
            Write-Host "Magic:      " $Character.Magic
            Write-Host "Is this acceptable? (y/n)"
            $in = Read-Host
    
            If ($in -eq "y") 
            {
                $continue = $true
                #Write Character to file
                Export-Character -Save $false
            }
            Else
            {
                New-Character
                Write-Host "`n"
            }
        }
    }
    ElseIf ($in -eq 2 -or $in -eq 'c')
    {
        #Continue Game
        Resume-Game
        If ($Character.Name -eq "")
        {
            Write-Host "Create a new character? (y/n)"
            $in = Read-Host
            If ($in -eq 'y')
            {
                New-Character
            }
            continue
        }
        while ($continue -eq $false)
        {
            Write-Host "`n"
            Write-Host $Character.Name", Level" $Character.Level $Character.Class
            Write-Host "Load this character? (y/n)"
            $in = Read-Host
            If ($in -eq "y")
            {
                $continue = $true
                #Start the game!
            }
            Else
            {
                Resume-Game
            }
        }
    }
    Else
    {
        Write-Host "Invalid input"
    }
}

$continue = $false
#Start the game

while ($Character.Health -gt 0)
{
    New-Room

    Write-Host "`n"
    $Room.Text
    If ($Room.Monster -eq $true)
    {
        Write-Host "A" $Monster.Name "approaches!"
        Read-Host
        Start-Battle
    }
    If ($Room.Skills.Count -gt 0)
    {
        Select-Skill
    }
    Export-Character -Save $true

    Write-Host "You continue to the next room..."
    Read-Host
}