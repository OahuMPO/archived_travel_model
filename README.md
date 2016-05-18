# OMPOTravelModel
Official Travel Model for the Oahu Metropolitan Planning Organization

## Repository Branch Structure

The branch structure borrows heavily from well-established guidlines. Namely:
<a href="http://nvie.com/posts/a-successful-git-branching-model/">http://nvie.com/posts/a-successful-git-branching-model/</a>

SourceTree supports this structure natively through the "Git Flow" button.  For full details on this feature, see:
<a href="http://blog.sourcetreeapp.com/2012/08/01/smart-branching-with-sourcetree-and-git-flow/">http://blog.sourcetreeapp.com/2012/08/01/smart-branching-with-sourcetree-and-git-flow/</a>

## Folder Structure

Important Note: Spaces are not allowed in the directory path where the model files are located.  This causes the java models to fail.

### 'generic'
This folder contains all data required to create any scenario.  This includes all availale socio-economic data, master highway and transit networks,
control files, programs, and scripts.  The model GUI in TransCAD is used to extract individual scenarios from this folder.

### 'scenarios'
This folder should contain each scenario created by the user.  The contents of this folder are ignored by Git to prevent
the repository from getting too large.  An example base-year scenario would be stored in the following directory:

scenarios\2012_base\

## Setting up Third-Part Software

This model requires a few other programs to be installed on the machine.

### TransCAD V6 Build 9030
Purchase/Download from Caliper.

Installation Directory:
C:\Program Files\TransCAD_6.0_bld_9030

For example, the bmp folder would be located here:
C:\Program Files\TransCAD_6.0_bld_9030\bmp

### Java Development Kit (JDK)
Download from:
http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

Installation Directory:
C:\Program Files\Java

For example, if the user downloaded JDK 8u31, the bin folder would be located here:
C:\Program Files\Java\jdk1.8.0_31\bin

### GnuWin32
In order to simplify model setup, this software is distributed along with the model files.
It is located in the generic\programs folder.

### Pointing the model to the third-party software

The model requires a file to point to the location of these three folders.  This is done
by changing the following file (in the model directory):
generic\programs\CTRampEnv.bat.example

First, make a copy of the file in the same location, and change the name of the copy to:
CTRampEnv.bat

Next, make sure the following three lines point to the correct location of each software
on your local machine.  As an example:

set JAVA_64_PATH=C:\Progra~1\Java\jdk1.8.0_31
set TRANSCAD_PATH=C:\Progra~1\TransCAD_6.0_bld_9030
set GNUWIN32_PATH=C:\projects\Honolulu\Version6\OMPORepo\generic\programs\GetGnuWin32\bin