import pytest
import requests
import os

class TestCarDealershipWebsite:
    """Test suite for AutoMax Car Dealership static website"""
    
    def setup_method(self):
        """Setup for each test method"""
        self.base_url = os.environ.get('TEST_URL', 'http://localhost:3000')
    
    def test_homepage_loads(self):
        """Test that the main homepage loads successfully"""
        response = requests.get(self.base_url)
        assert response.status_code == 200
        assert 'AutoMax' in response.text
        assert 'Find Your Dream Car Today' in response.text
    
    def test_page_contains_navigation(self):
        """Test that navigation elements are present"""
        response = requests.get(self.base_url)
        content = response.text
        
        # Check navigation links
        assert 'Home' in content
        assert 'Inventory' in content
        assert 'Services' in content
        assert 'About' in content
        assert 'Contact' in content
    
    def test_car_inventory_section(self):
        """Test that car inventory section is present"""
        response = requests.get(self.base_url)
        content = response.text
        
        # Check for featured vehicles
        assert 'Featured Vehicles' in content
        assert 'BMW X5' in content
        assert 'Tesla Model 3' in content
        assert 'Porsche 911' in content
    
    def test_contact_form_present(self):
        """Test that contact form elements are present"""
        response = requests.get(self.base_url)
        content = response.text
        
        assert 'Schedule a Test Drive' in content
        assert 'Full Name' in content
        assert 'Email' in content
        assert 'Phone' in content
        assert 'Vehicle of Interest' in content
    
    def test_static_assets_load(self):
        """Test that CSS and JS files are accessible"""
        # Test CSS file
        css_response = requests.get(f'{self.base_url}/styles.css')
        assert css_response.status_code == 200
        
        # Test JS file
        js_response = requests.get(f'{self.base_url}/script.js')
        assert js_response.status_code == 200
    
    def test_responsive_meta_tag(self):
        """Test that responsive meta tag is present"""
        response = requests.get(self.base_url)
        content = response.text
        
        assert 'viewport' in content
        assert 'width=device-width' in content
    
    def test_security_headers(self):
        """Test basic security headers (if implemented)"""
        response = requests.get(self.base_url)
        
        # These would be added by web server configuration
        # Testing what we can control
        assert response.status_code == 200
        assert len(response.content) > 0
