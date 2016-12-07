require 'spec_helper'

describe Enterprise do
  context "key-based caching invalidation" do
    describe "is touched when a(n)" do
      let(:enterprise) { create(:distributor_enterprise, updated_at: 1.week.ago) }
      let(:taxon) { create(:taxon) }
      let(:supplier2) { create(:supplier_enterprise) }

      describe "with a supplied product" do
        let(:product) { create(:simple_product, supplier: enterprise) }
        let!(:classification) { create(:classification, taxon: taxon, product: product) }
        let(:property) { product.product_properties.last }
        let(:producer_property) { enterprise.producer_properties.last }

        before do
          product.set_property 'Organic', 'NASAA 12345'
          enterprise.set_producer_property 'Biodynamic', 'ASDF 4321'
        end

        it "touches enterprise when a classification on that product changes" do
          expect { classification.save! }.to change { enterprise.updated_at }
        end

        it "touches enterprise when a property on that product changes" do
          expect { property.save! }.to change { enterprise.reload.updated_at }
        end

        it "touches enterprise when a producer property on that product changes" do
          expect { producer_property.save! }.to change { enterprise.reload.updated_at }
        end

        it "touches enterprise when the supplier of a product changes" do
          expect {
            product.update_attributes!(supplier: supplier2)
          }.to change { enterprise.updated_at }
        end
      end

      describe "with a distributed product" do
        let(:product) { create(:simple_product) }
        let(:oc) { create(:simple_order_cycle, distributors: [enterprise], variants: [product.variants.first]) }
        let(:supplier) { product.supplier }
        let!(:classification) { create(:classification, taxon: taxon, product: product) }
        let(:property) { product.product_properties.last }
        let(:producer_property) { supplier.producer_properties.last }

        before do
          product.set_property 'Organic', 'NASAA 12345'
          supplier.set_producer_property 'Biodynamic', 'ASDF 4321'
        end

        context "with an order cycle" do
          before { oc }

          it "touches enterprise when a classification on that product changes" do
            expect { classification.save! }.to change { enterprise.reload.updated_at }
          end

          it "touches enterprise when a property on that product changes" do
            expect { property.save! }.to change { enterprise.reload.updated_at }
          end

          it "touches enterprise when a producer property on that product changes" do
            expect { producer_property.save! }.to change { enterprise.reload.updated_at }
          end

          it "touches enterprise when the supplier of a product changes" do
            expect {
              product.update_attributes!(supplier: supplier2)
            }.to change { enterprise.reload.updated_at }
          end
        end

        it "touches enterprise when the product's variant is added to order cycle" do
          expect { oc }.to change { enterprise.reload.updated_at }
        end
      end

      describe "with relatives" do
        let(:child_enterprise) { create(:supplier_enterprise) }
        let!(:er) { create(:enterprise_relationship, parent: enterprise, child: child_enterprise) }

        it "touches enterprise when enterprise relationship is updated" do
          expect { er.save! }.to change { enterprise.reload.updated_at }
        end
      end

      describe "with shipping methods" do
        let(:sm) { create(:shipping_method) }

        before do
          enterprise.shipping_methods << sm
        end

        it "touches enterprise when distributor_shipping_method is updated" do
          expect {
            enterprise.distributor_shipping_methods.first.save!
          }.to change { enterprise.reload.updated_at }
        end

        it "touches enterprise when shipping method is updated" do
          expect { sm.save! }.to change { enterprise.reload.updated_at }
        end
      end

      it "touches enterprise when address is updated" do
        expect{ enterprise.address.save! }.to change { enterprise.reload.updated_at }
      end
    end
  end
end
