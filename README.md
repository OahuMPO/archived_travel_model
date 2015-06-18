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