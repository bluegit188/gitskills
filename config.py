import yaml
import numpy as np
import pandas as pd

# ==============================================================
# Config class
# ==============================================================

class Config:
    def __init__(self, yaml_path: str="config_scdtw.yaml"):
        with open(yaml_path, "r") as f:
            self.cfg = yaml.safe_load(f)
        self.load_from_dict(self.cfg)

    def load_from_dict(self, d: dict):
        self.dfile =d.get("dfile")
        self.NFold = d.get("NFold", 50)
        self.distType = d.get("distType", 4)
        self.SCBand = d.get("SCBand", 5)
        self.Ks = d.get("Ks", 2500)
        self.WFD =d.get("WFD",1)
        self.leakDist = d.get("leakDist", 30)
        self.colYNames = d.get("colYNames", [])
        self.colXNames = d.get("colXNames", [])      
        self.wgts = d.get("wgts", [])
 
    def __repr__(self):
        return f"<Config Ks={self.Ks}, leakDist={self.leakDist}, yvars={self.colYNames}>"

    def print(self):
        print(f"dfile: {self.dfile}")  
        print(f"NFold: {self.NFold}")
        print(f"distType: {self.distType}")
        print(f"SCBand: {self.SCBand}")
        print(f"Ks: {self.Ks}")
        print(f"WFD: {self.WFD}")        
        print(f"leakDist: {self.leakDist}")
        print(f"colYNames: {self.colYNames}")
        print(f"colXNames: {self.colXNames}")    
        print(f"wgts: {self.wgts}")
