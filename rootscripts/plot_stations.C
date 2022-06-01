TH2F* GetTH2(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH2F*)key->ReadObjectAny(TH2F::Class());
}

void plot_stations(int stations)
{
  TFile* fdigits = new TFile("qc-mch-digits.root");
  TFile* fpreclus = new TFile("qc-mch-preclusters.root");

  gStyle->SetOptStat(0);
  int cW = 1800;
  int cH = 1200;
  TCanvas c("c","c",cW,cH);
  TH1F* h1;
  TH2F* h2;
  TH2F* h2_2;


  // ==============================
  // Occupancy

  c.SetLogz(kTRUE);
  TString histname = TString::Format("Occupancy_ST%d", stations);
  h2 = GetTH2(fdigits, histname);
  if( h2 ) {
    h2->SetMinimum(0.000001);
    //h2->SetMaximum(0.1);
    h2->Draw("colz");
  }

  c.SaveAs(TString::Format("ST%d.pdf(", stations));
  c.SetLogy(kFALSE);


  // ==============================
  // Efficiency

  c.SetLogz(kFALSE);
  histname = TString::Format("Pseudoeff_ST%d", stations);
  h2 = GetTH2(fpreclus, histname);
  if( h2 ) {
    h2->SetMinimum(0);
    h2->SetMaximum(1);
    h2->Draw("colz");
  }

  c.SaveAs(TString::Format("ST%d.pdf)", stations));
  c.SetLogy(kFALSE);
}
