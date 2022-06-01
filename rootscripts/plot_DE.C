TH2F* GetTH2(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH2F*)key->ReadObjectAny(TH2F::Class());
}

void plot_DE(int de)
{
  TFile* fdigits = new TFile("qc-mch-digits.root");
  TFile* fpreclus = new TFile("qc-mch-preclusters.root");

  gStyle->SetOptStat(0);
  int cW = 600;
  int cH = 1200;
  if (de >= 500) {
    cW = 1800;
    cH = 1200;
  }
  TCanvas c("c","c",cW,cH);
  c.Divide(1,2);
  TH1F* h1;
  TH2F* h2;
  TH2F* h2_2;

  int Nch = de / 100;
  int station = (Nch - 1) / 2 + 1;


  // ==============================
  // Occupancy

  c.cd(1);
  gPad->SetLogz(kTRUE);
  TString histname = TString::Format("Expert/ST%d/DE%d/Occupancy_B_XY_%03d", station, de, de);
  h2 = GetTH2(fdigits, histname);
  if( h2 ) {
    h2->SetMinimum(0.000000001);
    //h2->SetMaximum(0.1);
    h2->Draw("colz");
  }

  c.cd(2);
  gPad->SetLogz(kTRUE);
  histname = TString::Format("Expert/ST%d/DE%d/Occupancy_NB_XY_%03d", station, de, de);
  h2 = GetTH2(fdigits, histname);
  if( h2 ) {
    h2->SetMinimum(0.000000001);
    //h2->SetMaximum(0.1);
    h2->Draw("colz");
  }

  c.SaveAs(TString::Format("DE%d.pdf(", de));
  c.SetLogy(kFALSE);


  // ==============================
  // Efficiency

  c.cd(1);
  gPad->SetLogz(kFALSE);
  histname = TString::Format("Expert/ST%d/DE%d/Pseudoeff_B_XY_%03d", station, de, de);
  h2 = GetTH2(fpreclus, histname);
  if( h2 ) {
    h2->SetMinimum(0);
    h2->SetMaximum(1);
    h2->Draw("colz");
  }

  c.cd(2);
  gPad->SetLogz(kFALSE);
  histname = TString::Format("Expert/ST%d/DE%d/Pseudoeff_NB_XY_%03d", station, de, de);
  h2 = GetTH2(fpreclus, histname);
  if( h2 ) {
    h2->SetMinimum(0);
    h2->SetMaximum(1);
    h2->Draw("colz");
  }

  c.SaveAs(TString::Format("DE%d.pdf)", de));
  c.SetLogy(kFALSE);
}
