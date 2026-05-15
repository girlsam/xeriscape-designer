module Api
  module V1
    class RecommendationsController < ApplicationController
      def create
        result = AiRecommendationService.call(
          messages: messages_param,
          current_design: current_design_param,
          zone: fetch_zone
        )

        response = { message: result[:message] }

        if result[:design]
          response[:design] = result[:design]
          response[:svg] = SvgRenderService.call(result[:design])
          response[:legend] = build_legend(result[:design])
        end

        render json: response.compact
      rescue AiRecommendationService::APIError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ZoneLookupService::ZoneNotFoundError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ZoneLookupService::NetworkError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      private

      def messages_param
        params.require(:messages).map do |m|
          { role: m.require(:role), content: m.require(:content) }
        end
      end

      def current_design_param
        @current_design_param ||= params[:current_design]&.to_unsafe_h&.deep_symbolize_keys
      end

      def fetch_zone
        zip = params[:zip_code].presence || current_design_param&.dig(:zip_code)
        ZoneLookupService.call(zip) if zip
      end

      def build_legend(design)
        design[:plants].map do |plant|
          plant.slice(:letter, :common_name, :scientific_name, :plant_type, :color, :mature_spread_ft, :mature_height_ft, :quantity)
        end
      end
    end
  end
end
