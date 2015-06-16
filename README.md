# OMPOTravelModel
Official Travel Model for the Oahu Metropolitan Planning Organization

## Repository Branch Structure

The branch structure borrows heavily from well-established guidlines. Namely:
<a href="http://nvie.com/posts/a-successful-git-branching-model/">http://nvie.com/posts/a-successful-git-branching-model/</a>

The structure of this repository has been simplified, as explained below.

### Master Branch
Contains only official versions of the model for distribution and use in planning applications.

### Milestone Branch
Contains only fully-working versions of the model.  There can be multiple milestone commits between master
branch updates as components of the model are updated.  Once all milestones are completed, this branch will be
merged into "master".

### Feature Branches
These branches will be used when working on individual model components.  Not all commits need to be fully operational.

### Example
While working on trip generation, a "trip gen" branch will contain many commits per day.  Once the new trip gen model
is working, the branch will be merged into 'milestone'.  Once all components of the model have been updated, (trip gen, distribution,
assignment, etc.), the 'milestone' branch will be given a final check for errors before being merged into 'master'.

## Folder Structure

### 'generic'
This folder contains all data required to create any scenario.  This includes all availale socio-economic data, master highway and transit networks,
control files, programs, and scripts.  The model GUI in TransCAD is used to extract individual scenarios from this folder.

### 'scenarios'
This folder should contain each scenario created by the user.  The contents of this folder are ignored by Git to prevent
the repository from getting too large.  An example base-year scenario would be stored in the following directory:

scenarios\2012_base\