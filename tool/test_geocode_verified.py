import unittest
from geocode_verified import clean_address,validate_candidate,select_candidate
from enrich_municipal import street_key,code
class GeocodingValidationTests(unittest.TestCase):
 def setUp(self):
  self.geo={'district':'SANTIAGO DE SURCO','latitude':-12.145,'longitude':-77.005}
  self.candidate={'place_rank':30,'lat':'-12.0993','lon':'-76.9701','display_name':'55, Avenida El Derby, Santiago de Surco, Lima, Perú','address':{'country_code':'pe','house_number':'55','road':'Avenida El Derby'}}
 def test_accepts_address_and_normalizes_leading_zero(self):
  self.assertTrue(validate_candidate(self.candidate,'AV. EL DERBY NRO 055',self.geo)[0])
 def test_does_not_promote_road_centroid(self):
  self.candidate['place_rank']=26
  self.assertFalse(validate_candidate(self.candidate,'AV. EL DERBY NRO 055',self.geo)[0])
 def test_does_not_promote_wrong_number(self):
  self.candidate['address']['house_number']='155'
  self.assertFalse(validate_candidate(self.candidate,'AV. EL DERBY NRO 055',self.geo)[0])
 def test_does_not_promote_wrong_street(self):
  self.candidate['address']['road']='Avenida Javier Prado'
  self.assertFalse(validate_candidate(self.candidate,'AV. EL DERBY NRO 055',self.geo)[0])
 def test_does_not_promote_wrong_district(self):
  self.candidate['display_name']='55, Avenida El Derby, Miraflores, Lima, Perú'
  self.assertFalse(validate_candidate(self.candidate,'AV. EL DERBY NRO 055',self.geo)[0])
 def test_cleans_fiscal_address(self):
  self.assertEqual(clean_address('CAL. LAS BEGONIAS NRO 441 INT 1401 URB. JARDIN'),'Calle LAS BEGONIAS 441')
class MunicipalNormalizationTests(unittest.TestCase):
 def test_official_calle_alias(self):
  self.assertEqual(street_key('Ca. Las Begonias'),street_key('LAS BEGONIAS','CAL.'))
 def test_different_road_types_are_not_merged(self):
  self.assertNotEqual(street_key('Av. Jose Galvez'),street_key('Ca. Jose Galvez'))
 def test_leading_zero_street_codes(self):
  self.assertEqual(code('0039'),code(39))
 def test_duplicate_osm_entrances_same_address(self):
  a={'lat':'-12.1','lon':'-77.03'};b={'lat':'-12.10001','lon':'-77.03001'}
  self.assertEqual(len(select_candidate([a,b])),1)
 def test_distant_matching_numbers_stay_ambiguous(self):
  a={'lat':'-12.1','lon':'-77.03'};b={'lat':'-12.102','lon':'-77.032'}
  self.assertEqual(len(select_candidate([a,b])),2)
if __name__=='__main__':unittest.main()
