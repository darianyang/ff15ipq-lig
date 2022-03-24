## These files are still in development
---
## Deriving Bonded IPolQ Force Field Parameters

### The workflow for the bonded parameter derivation process is as follows:

*Note that here I am only adjusting the dihedrals and not the angle or bonded parameters, which are taken from GAFF. The thought behind this is that the torsion adjustments will implicitly account for any discrepancies in the charge model with other bonded parameters; however, you may include angle and bonded parameters in your fitting procedure, if you so choose. See the Amber manual mdgx section or the ipq parameter tutorials for more information on how to do this.*

#### Script 0
