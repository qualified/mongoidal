# 0.2.0
- Revision#restore! now does a full restore of changes to that point, and saves as a new revision, instead of removing old history 

# 0.1.14
- RevisableBase#max_revision_number method optimized
- revision associations are no longer validated

# 0.1.13
- ExternalRevisions are now properly saved when calling revise!