##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

import os, cadence; print '\n'.join(sorted((cadence.flattenCds(os.getenv('CDSLIB'))).keys()))
