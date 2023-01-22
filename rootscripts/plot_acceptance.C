TH1F* GetTH1(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH1F*)key->ReadObjectAny(TH1F::Class());
}

TH2F* GetTH2(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH2F*)key->ReadObjectAny(TH2F::Class());
}

void plot_acceptance()
{
  //TFile* fmchmid = new TFile("qc-mchmid-tracks.root");
  TFile* fmchmid = new TFile("Outputs/run00523252/qc-mftmchmid-tracks.root");

  gStyle->SetOptStat(0);
  gStyle->SetOptFit(1111);
  gStyle->SetPalette(57, 0);
  gStyle->SetNumberContours(40);
  int cW = 1800;
  int cH = 1200;
  TCanvas c("c","c",cW,cH);
  //gPad->SetLogy(kTRUE);

  TH1F* hRAbs = GetTH1(fmchmid, "MCH/TrackRAbs");
  hRAbs->Draw();
  c.SaveAs("acceptance.pdf(");

  TH2F* hMIDall = GetTH2(fmchmid, "MCH/TrackPosMID");
  TH2F* hMIDmatched = GetTH2(fmchmid, "MCH-MID/TrackPosMID");

  hMIDall->Draw("colz");
  c.SaveAs("acceptance.pdf");

  hMIDmatched->Divide(hMIDall);
  hMIDmatched->SetMinimum(0);
  hMIDmatched->SetMaximum(1);
  hMIDmatched->Draw("colz");

  c.SaveAs("acceptance.pdf)");
}
