"""Contract tests: never package failed or divergent evidence as equivalent."""
import runpy
import unittest
from pathlib import Path

contract = runpy.run_path(str(Path(__file__).with_name('package-candidate.py')))
verify = contract['verify_pair']


class EvidenceContract(unittest.TestCase):
    def report(self):
        return {'assertions':42,'failures':[],'stateHash':'same','campaignEdition':29,'orders':7865,'measurements':{'equivalence':{'cases':95,'decisionsHash':'stable'}}}

    def test_matching_passes(self):
        verify(self.report(),self.report(),42)

    def test_failed_or_short_suite_is_rejected(self):
        for change in [{'failures':['lost save']},{'assertions':41}]:
            with self.subTest(change=change), self.assertRaises(AssertionError):
                verify(self.report(),{**self.report(),**change},42)

    def test_divergence_is_rejected(self):
        for change in [{'stateHash':'changed'},{'campaignEdition':28},{'orders':7864},{'measurements':{'equivalence':{'cases':95,'decisionsHash':'changed'}}}]:
            with self.subTest(change=change), self.assertRaises(AssertionError):
                verify(self.report(),{**self.report(),**change},42)


if __name__ == '__main__': unittest.main()
