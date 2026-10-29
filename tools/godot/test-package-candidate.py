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

    def test_profile_identity_contract_is_compared(self):
        base = {**self.report(),'profileSchema':2}
        with self.assertRaises(AssertionError):
            verify(base,{**base,'profileSchema':1},42)

    def test_product_identity_and_legacy_compatibility_must_match(self):
        identity = {'name':'Tactical Chronicles','userDirectoryPreserved':True}
        base = {**self.report(),'branding':identity}
        for change in [{'name':'Old product','userDirectoryPreserved':True},{'name':'Tactical Chronicles','userDirectoryPreserved':False}]:
            with self.subTest(change=change), self.assertRaises(AssertionError):
                verify(base,{**base,'branding':change},42)

    def test_rc2_requires_its_own_profile_suite(self):
        if contract['VERSION'] != '1.0.0-rc.2': self.skipTest('Only the RC2 presentation package')
        self.assertIn('profile',contract['SUITES'])
        self.assertIn('collection',contract['SUITES'])
        self.assertNotIn('closing-playthrough',contract['SUITES'])
        self.assertIn('RELEASE_1_0_RC2.md',contract['PLAYER_DOCS'])


if __name__ == '__main__': unittest.main()
