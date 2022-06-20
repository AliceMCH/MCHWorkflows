TH2F* GetTH2(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH2F*)key->ReadObjectAny(TH2F::Class());
}

void plot_calib_DE(int de)
{
  TFile* fcalib = new TFile("qc-mch-pedestals.root");

  gStyle->SetOptStat(0);
  gStyle->SetPalette(57, 0);
  gStyle->SetNumberContours(40);
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
  gPad->SetLogz(kFALSE);
  TString histname = TString::Format("ST%d/DE%d/Noise_XY_B_%03d", station, de, de);
  h2 = GetTH2(fcalib, histname);
  if( h2 ) {
    h2->SetMinimum(0);
    h2->SetMaximum(1);
    h2->Draw("colz");
  }

  c.cd(2);
  gPad->SetLogz(kFALSE);
  histname = TString::Format("ST%d/DE%d/Noise_XY_NB_%03d", station, de, de);
  h2 = GetTH2(fcalib, histname);
  if( h2 ) {
    h2->SetMinimum(0);
    h2->SetMaximum(1);
    h2->Draw("colz");
  }

  c.SaveAs(TString::Format("noise-DE%d.pdf", de));
  c.SetLogy(kFALSE);
}
